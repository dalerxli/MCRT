Module EnergyBundleLocation

!********************************************************************************
!        PURPSOE:        Locating the position of the emitted or reflected EnergyBundle
!                                on a surface and the direction of the ray
!
!        CREATED BY:        Bereket A. Nigusse                10.19.04
!
!
!!*******************************************************************************

   USE GLOBAL
   USE EnclosureGeometry

   IMPLICIT NONE
   CONTAINS

   SUBROUTINE EnergySourceLocation()
!********************************************************************************
!
!   Purpose: Checks whether the surface rectangular or triangular, then calls
!            the appropriate subroutine. If the fourth vertex index is zero
!            then the polygon is triangular, else it is rectangular
!
!********************************************************************************
      INTEGER :: I, J, K, IOS

      !INTEGER, ALLOCATABLE :: OldRandSeed(:)
      !
      !ALLOCATE (OldRandSeed(NumSeed))
      !
      !Call RANDOM_SEED(GET=OldRandSeed(1:NumSeed))
      Call RANDOM_NUMBER(Rand)
      IF (PolygonIndex(SIndex) .eq. 4) Then
         CALL RectangularSurface()
      ELSEIF (PolygonIndex(SIndex) .eq. 3) Then
         CALL TriangularSurface()
      ELSE
      Endif
   END SUBROUTINE EnergySourceLocation

   SUBROUTINE TriangularSurface()
!*******************************************************************************
!
!   Purpose: Determines the location of the emitted energy on a triangular
!            surface randomly
!
!
!*******************************************************************************
!   Rand                  Normalized uniform distribution Random numbers between 0 and 1
!   XLS                   Location of x-coordinate of the source on a particular surface
!   YLS                   Location of y-coordinate of the source on a particular surface
!   ZLS                   Location of z-coordinate of the source on a particular surface
!   VS(4)                 The four vertices used to define a surface and are inputs
!   X, Y, Z               The coordinates of a vertex

      IMPLICIT NONE
      INTEGER :: I, J, K, IOS
      INTEGER, DIMENSION(:) :: VS(4)
      REAL(Prec2), DIMENSION(4) :: X, Y, Z
      REAL(Prec2), DIMENSION(:, :) :: Vedge1(3), Vedge2(3)
      REAL(Prec2) :: Randu, Randv

!  If it is a reflected energy bundle, no need to calculate the emission point
      IF (Reflected) Then
         XLS(SIndex) = Xo(SInter)
         YLS(SIndex) = Yo(SInter)
         ZLS(SIndex) = Zo(SInter)
      ELSE
         DO J = 1, 3 !Calculates emission point
            VS(J) = SVertex(SIndex, J)
            X(J) = XS(VS(J))
            Y(J) = YS(VS(J))
            Z(J) = ZS(VS(J))
         END DO
!   Calculates two edge vectors for a triangular polygon
         Vedge1(1) = (X(2) - X(1))
         Vedge1(2) = (Y(2) - Y(1))
         Vedge1(3) = (Z(2) - Z(1))
!
         Vedge2(1) = (X(3) - X(1))
         Vedge2(2) = (Y(3) - Y(1))
         Vedge2(3) = (Z(3) - Z(1))

         !Generating random numbers
         !The following equations are from Dr. Spitler's notes, Monte Carlo Ray Tracing in Radiation Heat Transfer
         Randu = 1 - SQRT(1 - Rand(1))
         Randv = (1 - Randu)*Rand(2)

         XLS(SIndex) = X(1) + Randu*Vedge1(1) + Randv*Vedge2(1)
         YLS(SIndex) = Y(1) + Randu*Vedge1(2) + Randv*Vedge2(2)
         ZLS(SIndex) = Z(1) + Randu*Vedge1(3) + Randv*Vedge2(3)

      ENDIF
   END SUBROUTINE TriangularSurface

   SUBROUTINE RectangularSurface
!*******************************************************************************
!
!   Purpose: Calculates the location of the emitted energy on a rectangular
!            surface randomly
!
!
!*******************************************************************************
!   Rand                  Normalized uniform distribution Random numbers between 0 and 1
!   XLS                   Location of x-coordinate of the source on a particular surface
!   YLS                   Location of y-coordinate of the source on a particular surface
!   ZLS                   Location of z-coordinate of the source on a particular surface
!   VS(4)                 The four vertices used to define a surface and are inputs
!   X, Y, Z               The coordinates of a vertex

      IMPLICIT NONE
      INTEGER :: I, J, K, IOS
      Integer, DIMENSION(:) :: VS(4)
      REAL(prec2), ALLOCATABLE, DIMENSION(:) :: SurfaceE
      REAL(Prec2), DIMENSION(4) :: X, Y, Z
      REAL(Prec2), DIMENSION(:, :) :: Vedge1(3), Vedge2(3), Vedge3(3) ! Dividing the rectangles into triangles
      REAL(Prec2) :: Randu, Randv
!
! If the energy is reflected then its location will be the point of intersection
      IF (Reflected) Then
         XLS(SIndex) = Xo(SInter)
         YLS(SIndex) = Yo(SInter)
         ZLS(SIndex) = Zo(SInter)

      ELSE
         DO J = 1, 4 !Otherwise, determine emission location
            VS(J) = SVertex(SIndex, J)
            X(J) = XS(VS(J))
            Y(J) = YS(VS(J))
            Z(J) = ZS(VS(J))
         END DO

         Vedge1(1) = (X(2) - X(1))
         Vedge1(2) = (Y(2) - Y(1))
         Vedge1(3) = (Z(2) - Z(1))

         Vedge2(1) = (X(4) - X(1))
         Vedge2(2) = (Y(4) - Y(1))
         Vedge2(3) = (Z(4) - Z(1))

         Vedge3(1) = (X(3) - X(1))
         Vedge3(2) = (Y(3) - Y(1))
         Vedge3(3) = (Z(3) - Z(1))

         !The following equations are from Dr. Spitler's notes, Monte Carlo Ray Tracing in Radiation Heat Transfer
         Randu = 1 - SQRT(1 - Rand(1))
         Randv = (1 - Randu)*Rand(2)

         IF (Rand(7) .GT. 0.5) THEN
            XLS(SIndex) = X(1) + Randu*Vedge1(1) + Randv*Vedge3(1)
            YLS(SIndex) = Y(1) + Randu*Vedge1(2) + Randv*Vedge3(2)
            ZLS(SIndex) = Z(1) + Randu*Vedge1(3) + Randv*Vedge3(3)
         ELSE
            XLS(SIndex) = X(1) + Randu*Vedge2(1) + Randv*Vedge3(1)
            YLS(SIndex) = Y(1) + Randu*Vedge2(2) + Randv*Vedge3(2)
            ZLS(SIndex) = Z(1) + Randu*Vedge2(3) + Randv*Vedge3(3)
         END IF

         IF (XLS(SIndex) .LT. 0 .OR. YLS(SIndex) .LT. 0 .OR. ZLS(SIndex) .LT. 0) THEN
            WRITE (*, *) 'Error! Check the vertices on your input file.'
         END IF

      ENDIF
   END SUBROUTINE RectangularSurface

   SUBROUTINE InitializeSeed()
!******************************************************************************
!
!   PURPOSE:        Initialization of seed for the random Number generator
!
!
!******************************************************************************
      IMPLICIT NONE
      INTEGER :: K
      INTEGER, DIMENSION(:) ::  SEEDARRAY(7), OLDSEED(7)
!    Sets K = N
      K = 7
      CALL RANDOM_SEED(SIZE=K)
!    Set user seed
      CALL RANDOM_SEED(PUT=SEEDARRAY(1:K))
!    Get current seed
      CALL RANDOM_SEED(GET=OLDSEED(1:K))
   END SUBROUTINE InitializeSeed

   SUBROUTINE TangentVectors()
!*******************************************************************************
!
!   PURPOSE:        Determines unit tangent vectors on a surface in the enclosure
!
!
!*******************************************************************************
!   UV_X(3)                Unit vector along -direction
!   UV_Y(3)                Unit vector along Y-direction
!   UV_Z(3)                Unit vector along Z-direction
!   TUV1(3)                Unit vector tangent to the source point on a surface
!   TUV2(3)                Unit vector tangent to the source point on a surface and
!                          normal to the TUV1 tangent vector
!                          The tangent vectors are used for reference in defining the angle
!                          Thus, need to be determined once for each surface
!   SmallestRealNo         The smallest machine number
!
      IMPLICIT NONE
      INTEGER :: I, J, K, IOS, INDEX
      REAL(Prec2) ::  UV_x(3), UV_y(3), UV_z(3), V(3), TUV1(3), TUV2(3), VDOT(3)
      REAL(Prec2) ::        SmallestRealNo, NV, xx
!
!     define the smallest machine number
      SmallestRealNo = EPSILON(0.0d0)
!
      ALLOCATE (Tan_V1(NSurf, 3), Tan_V2(NSurf, 3), STAT=IOS)
      DO I = 1, 3
         Tan_V1(SIndex, I) = 0.0
         Tan_V2(SIndex, I) = 0.0
         V(I) = NormalUV(SIndex, I)
         UV_x(I) = 0.0
         UV_y(I) = 0.0
         UV_z(I) = 0.0
      END DO
      UV_x(1) = 1.0
      UV_y(2) = 1.0
      UV_z(3) = 1.0

!    The first tangent vector is determined first as follows
      VDOT(1) = DOT_PRODUCT(V, UV_x)
      VDOT(2) = DOT_PRODUCT(V, UV_y)
      VDOT(3) = DOT_PRODUCT(V, UV_z)
      If ((1.0-abs(VDOT(1))) .gt. SmallestRealNo) Then
         Call CrossProduct(V, UV_x, TUV1)
      ELseif ((1.0-abs(VDOT(2))) .gt. SmallestRealNo) Then
         Call CrossProduct(V, UV_y, TUV1)
      Else
         Call CrossProduct(V, UV_z, TUV1)
      ENDIF
!    JDS 11-8-06 attempt to eliminate linking problem with Norm_V
!         NV = Norm_V(TUV1)
      NV = sqrt(DOT_PRODUCT(TUV1, TUV1))
      DO J = 1, 3
         TUV1(J) = TUV1(J)/NV
         Tan_V1(SIndex, J) = TUV1(J)
      END DO
!
!  The second tangent vector is given by the cross product of the surface normal
!  vector and the first tangent vector
      Call CrossProduct(V, TUV1, TUV2)
      DO J = 1, 3
         Tan_V2(SIndex, J) = TUV2(J)
      END DO
!
   END SUBROUTINE TangentVectors
!
   SUBROUTINE DirectionEmittedEnergy()
!******************************************************************************
!
!   PURPOSE: Determines the direction of the emitted energy bundle
!
!
!******************************************************************************
!   THETA                The angle of the emitted energy bundle makes with the normal to
!                        the surface
!   PHI                  Polar angle of the emitted energy bundle
!   Rand(4)              Random number for zenith angle theta
!   Rand(5)              Random number for azimuth angle phi
!
      IMPLICIT NONE
      INTEGER                :: IOS, J
      REAL(Prec2)        :: Theta, Phi, Pi, DotTheta, MagVec !Theta1, Theta2,
      INTEGER, DIMENSION(:) :: VS(4)
      REAL(Prec2), DIMENSION(:, :) :: InVecDirec(3), SurfNorm(3) !RS: Incoming Vector Direction and Surface Normal
      REAL(Prec2), DIMENSION(4) :: X, Y, Z
!
!  Calculate emitted energy bundle direction angles
      Pi = 4.*Atan(1.)
      Theta = asin(sqrt(Rand(4)))
      Phi = 2.*Pi*Rand(5)
      ALLOCATE (EmittedUV(NSurf, 3), STAT=IOS)
! Calculate the unit vector in the direction of the emitted energy bundle
      If (Spindex .eq. 1) then !RS: For Specular Rays
         IF (Reflected) Then !RS: If the rays are being reflected off of another surface

            SurfNorm(1) = NormalUV(SIndex, 1) !Surface normal unit vector
            SurfNorm(2) = NormalUV(SIndex, 2)
            SurfNorm(3) = NormalUV(SIndex, 3)

            !Taking the incoming direction from the specified emission direction
            IF (TCountSpecR .EQ. 1) THEN !If the ray is being reflected for the first time
               MagVec = SQRT(DirectionX(OldSurface)**2 + DirectionY(OldSurface)**2 + DirectionZ(OldSurface)**2)
               InVecDirec(1) = -DirectionX(OldSurface)/MagVec !I is negative since the ray is incoming
               InVecDirec(2) = -DirectionY(OldSurface)/MagVec
               InVecDirec(3) = -DirectionZ(OldSurface)/MagVec
            ELSE !If the ray is being rereflected
               InVecDirec(1) = -EmittedUV(OldSurface, 1)
               InVecDirec(2) = -EmittedUV(OldSurface, 2)
               InVecDirec(3) = -EmittedUV(OldSurface, 3)
            END IF

            DotTheta = DOT_PRODUCT(InVecDirec, SurfNorm) !Dot product of the incoming ray and surface normal

            !r=2(I dot n)n -I   !Page 5, Nancy Pollard, 2004, http://graphics.cs.cmu.edu/nsp/course/15-462/Spring04/slides/13-ray.pdf

            EmittedUV(SIndex, 1) = 2*DotTheta*SurfNorm(1) - InVecDirec(1)
            EmittedUV(SIndex, 2) = 2*DotTheta*SurfNorm(2) - InVecDirec(2)
            EmittedUV(SIndex, 3) = 2*DotTheta*SurfNorm(3) - InVecDirec(3)

         ELSE !If Not Reflected
            EmittedUV(SIndex, 1) = DirectionX(SIndex)
            EMittedUV(SIndex, 2) = DirectionY(SIndex)
            EmittedUV(Sindex, 3) = DirectionZ(SIndex)
         END IF

         CALL CheckDirection

      Else
         EmittedUV(SIndex, 1) = NormalUV(SIndex, 1)*cos(Theta) + Tan_V1(SIndex, 1) &
                                *sin(Theta)*cos(Phi) + Tan_V2(SIndex, 1)*sin(Theta)*sin(Phi)
         EmittedUV(SIndex, 2) = NormalUV(SIndex, 2)*cos(Theta) + Tan_V1(SIndex, 2) &
                                *sin(Theta)*cos(Phi) + Tan_V2(SIndex, 2)*sin(Theta)*sin(Phi)
         EmittedUV(SIndex, 3) = NormalUV(SIndex, 3)*cos(Theta) + Tan_V1(SIndex, 3) &
                                *sin(Theta)*cos(Phi) + Tan_V2(SIndex, 3)*sin(Theta)*sin(Phi)
      End If

   END SUBROUTINE DirectionEmittedEnergy

   SUBROUTINE CheckDirection

      !RS:Debugging: Trying to set direction=0 if it doesn't exist

      IF (EMittedUV(SIndex, 1) .LT. (-10E10) .OR. EmittedUV(SIndex, 1) .GT. (10E10)) THEN
         EMittedUV(SIndex, 1) = 0
      END IF

      IF (EMittedUV(SIndex, 2) .LT. (-10E10) .OR. EmittedUV(SIndex, 2) .GT. (10E10)) THEN
         EMittedUV(SIndex, 2) = 0
      END IF

      IF (EMittedUV(SIndex, 3) .LT. (-10E10) .OR. EmittedUV(SIndex, 3) .GT. (10E10)) THEN
         EMittedUV(SIndex, 3) = 0
      END IF

   END SUBROUTINE

End Module EnergyBundleLocation
