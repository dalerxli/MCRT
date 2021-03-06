
MODULE EnclosureGeometry
!******************************************************************************
!
!  MODULE:        EnclosureGeometry
!
!  PURPOSE:       Reads the enclosure Geometry (vertex and vertices coordinates
!                 data) from a file for use in the program for surface equation
!                 determination
!
!******************************************************************************

USE Global
USE StringUtility
IMPLICIT NONE

CONTAINS

SUBROUTINE CalculateGeometry()

    IMPLICIT NONE
    INTEGER :: I, VertIndex, SurfIndex, TypeIndex, IOS
    CHARACTER (Len = 12) :: ReadStr
    REAL(Prec2) TotalReflec

    NVertex = 0
    NSurf = 0

    ! Count verticies and surfaces so we can allocate arrays
    DO
        ReadStr = ''
        READ (2, *, IOSTAT = IOS) ReadStr
        IF (StrLowCase(TRIM(ReadStr)) == "v") THEN
            NVertex = NVertex + 1
        ELSE IF (StrLowCase(TRIM(ReadStr)) == "s") THEN
            NSurf = NSurf + 1
        END IF

        IF (IS_IOSTAT_END(IOS)) THEN
            EXIT
        ENDIF
    END DO

    REWIND(2)

    !  Allocate the size of the array
    ALLOCATE(V(NVertex), XS(NVertex), YS(NVertex), ZS(NVertex), STAT = IOS)
    ALLOCATE(SNumber(NSurf), SVertex(NSurf, NSurf), SType(NSurf), BaseP(NSurf), CMB(NSurf), Emit(NSurf), SurfName(NSurf), STAT = IOS)
    ALLOCATE(DirectionX(NSurf), DirectionY(NSurf), DirectionZ(NSurf), SpecReflec(NSurf), DiffReflec(NSurf), FracSpecEmit(NSurf), FracSpecReflec(NSurf))

    ! Initialize arrays
    DirectionX = 0
    DirectionY = 0
    DirectionZ = 0
    SpecReflec = 0
    DiffReflec = 0
    FracSpecEmit = 0
    FracSpecReflec = 0

201 FORMAT(A1, ' ', I2, 3(' ', f6.3))
203 FORMAT(A1, 5('  ', I2), 1('  ',f6.3), 1('  ',I2), 1('  ',f6.3), A15)

    ! Now, read all data into arrays
    DO
        ReadStr = ''
        READ (2, *, IOSTAT = IOS) ReadStr
        IF (StrLowCase(TRIM(ReadStr)) == "v") THEN

            ! Read in vertex information
            BACKSPACE(2)
            READ (2, *) ReadStr, VertIndex, XS(VertIndex), YS(VertIndex), ZS(VertIndex)
            V(VertIndex) = VertIndex

            ! Write vertex data for RTVT
            IF (WriteLogFile) THEN
                WRITE(4, 201, ADVANCE = 'YES') TRIM(ReadStr), VertIndex, XS(VertIndex), YS(VertIndex), ZS(VertIndex)
            END IF

        ELSE IF (StrLowCase(TRIM(ReadStr)) == "s") THEN

            ! Read in surface information
            BACKSPACE(2)
            READ (2, *) ReadStr, SurfIndex, (SVertex(SurfIndex, I), I = 1, 4), BaseP(SurfIndex), CMB(SurfIndex), Emit(SurfIndex), SurfName(SurfIndex)
            SNumber(SurfIndex) = SurfIndex

            ! Write surface data for RTVT
            IF (WriteLogFile) THEN
                WRITE(4, 203) TRIM(ReadStr), SurfIndex, (SVertex(SurfIndex, I), I = 1, 4), BaseP(SurfIndex), CMB(SurfIndex), Emit(SurfIndex), SurfName(SurfIndex)
            END IF

        ELSE IF (StrLowCase(TRIM(ReadStr)) == "t") THEN

            ! Read in surface type information
            BACKSPACE(2)
            READ(2, *) ReadStr, TypeIndex, SType(TypeIndex)
            BACKSPACE(2)
            IF (StrUpCase(SType(TypeIndex)) == "SDE") THEN
                READ(2, *) ReadStr, SNumber(TypeIndex), SType(TypeIndex), DirectionX(TypeIndex), DirectionY(TypeIndex), DirectionZ(TypeIndex), FracSpecEmit(TypeIndex), FracSpecReflec(TypeIndex)
            ELSE IF (StrUpCase(SType(TypeIndex)) == "SDRO") THEN
                READ(2, *) ReadStr, SNumber(TypeIndex), SType(TypeIndex), FracSpecReflec(TypeIndex) ! Reading in specular and diffuse reflection
            ELSE
                READ(2, *) ReadStr, SNumber(TypeIndex), SType(TypeIndex)
            END IF
        END IF

        IF (IS_IOSTAT_END(IOS)) THEN
            EXIT
        ENDIF
    END DO

    ! Check for out of range specular/emitting fractions
    DO I = 1, NSurf
        IF (FracSpecEmit(I) .gt. 1) THEN
            FracSpecEmit(I) = 1
        ELSE IF (FracSpecEmit(I) .lt. 0) THEN
            FracSpecEmit(I) = 0
        END IF

        IF (FracSpecReflec(I) .gt. 1) THEN
            FracSpecReflec(I) = 1
        ELSE IF (FracSpecReflec(I) .lt. 0) THEN
            FracSpecReflec(I) = 0
        END IF
    END DO

    ! If no surface types were provided, set them to DIF here
    ! Update reflectance/emittance values and fractions here
    DO I = 1, NSurf
        IF (StrUpCase(SType(I)) == "SDE") THEN
            TotalReflec = 1 - Emit(I)
            DiffReflec(I) = TotalReflec * (1 - FracSpecReflec(I))
            SpecReflec(I) = TotalReflec * FracSpecReflec(I)
        ELSE IF (StrUpCase(SType(I)) == "SDRO") THEN
            TotalReflec = 1 - Emit(I)
            DiffReflec(I) = TotalReflec * (1 - FracSpecReflec(I))
            SpecReflec(I) = TotalReflec * FracSpecReflec(I)
        ELSE
            SType(I) = "DIF"
            DiffReflec(I) = 1 - Emit(I)
        END IF
    END DO

    CLOSE(Unit = 2)

END Subroutine  CalculateGeometry

SUBROUTINE CalculateSurfaceEquation()
!******************************************************************************
!
!  SUBROUTINE:    CalculateSurfaceEquation
!
!  PURPOSE:       Determines the coefficients of the surface equation using
!                 surface normal vector a point on the surface. The equation
!                 is of the form Ax + By + Cz + D  = 0
!
!******************************************************************************

!  Calculating the normal vector of the surfaces in the enclosure and the
!  coefficients of the surface equation. The equations is determined in
!  Cartesian coordinate system

    IMPLICIT NONE
    INTEGER :: I, J, K, M, IOS
    INTEGER, DIMENSION (:) :: VS(4)
    REAL(Prec2),  DIMENSION (4) :: X, Y, Z
    REAL(Prec2), DIMENSION (:, :) :: V_x(SIndex, 2), V_y(SIndex, 2), V_z(SIndex, 2)

    !  V_x(SIndex, 2)   Vectors on a surface used for normal vector determination
    !  V_y(SIndex, 2)   Vectors on a surface used for normal vector determination
    !  V_z(SIndex, 2)   Vectors on a surface used for normal vector determination
    !  X               x  - coordinate of a vertix
    !  Y               y  - coordinate of a vertix
    !  Z               z  - coordinate of a vertix

    ALLOCATE (SPlane(NSurf), NormalV(NSurf, 3), NormalUV(NSurf, 3), PolygonIndex(NSurf), STAT = IOS)

    !   Assign the vertices of a surfaces their corresponding vertices
    DO J = 1, 4
        VS(J) = SVertex(SIndex, J)
    END DO

    DO J = 1, 4
        IF(VS(4) .ne. 0 .or. J < 4)THEN
            X(J) = XS(VS(J))
            Y(J) = YS(VS(J))
            Z(J) = ZS(VS(J))
        ELSEIF(VS(4) .eq. 0)THEN
            X(4) = XS(VS(1))
            Y(4) = YS(VS(1))
            Z(4) = ZS(VS(1))
       ENDIF
    END DO

    IF(VS(4) == 0)THEN
       PolygonIndex(SIndex) = 3
    ELSE
       PolygonIndex(SIndex) = 4
    ENDIF

    DO I = 1, 2
        V_x(SIndex, I) = X(I + 1) - X(I)
        V_y(SIndex, I) = Y(I + 1) - Y(I)
        V_z(SIndex, I) = Z(I + 1) - Z(I)
    END DO

    CALL SurfaceNormal(V_x, V_y, V_z)

!    Allocate size of the array for coefficients of surface equation
    ALLOCATE (A(NSurf), B(NSurf), C(NSurf), D(NSurf), STAT = IOS)

    DO J = 1, 4
         VS(J) = SVertex(SIndex, J)
         IF(VS(4) .eq. 0)THEN
         ELSE
              X(J) = XS(VS(J))
             Y(J) = YS(VS(J))
             Z(J) = ZS(VS(J))
         ENDIF
    END DO

    ! Calculates the coefficients of the surface equation
    A(SIndex) = NormalUV(SIndex, 1)
    B(SIndex) = NormalUV(SIndex, 2)
    C(SIndex) = NormalUV(SIndex, 3)
    D(SIndex) = - (X(1) * A(SIndex) + Y(1) * B(SIndex) + Z(1) * C(SIndex))

END SUBROUTINE CalculateSurfaceEquation

SUBROUTINE SurfaceNormal(Vx, Vy, Vz)
!******************************************************************************
!
!  PURPOSE:        Determine normal unit vector of the surfaces in the enclosure
!
!
!******************************************************************************
    IMPLICIT NONE
    INTEGER :: I, J, K
    REAL(Prec2) :: NV(SIndex), Vector(3) !Norm_V,
    REAL(Prec2), DIMENSION (:, :) :: Vx(SIndex, 2), Vy(SIndex, 2), Vz(SIndex, 2)

    ! Norm_V         Magnitude of a vector
    ! NV(SIndex)     Magnitude of a normal vector of a surface SIndex
    ! Vector(3)      Coefficients of a normal vector

    ! Calculates the cross product of the vectors on a surface to determine the
    ! Surface Normal vector
    NormalV(SIndex, 1) = Vy(SIndex, 1) * Vz(SIndex, 2) - Vz(SIndex, 1) * Vy(SIndex, 2)
    NormalV(SIndex, 2) = Vz(SIndex, 1) * Vx(SIndex, 2) - Vx(SIndex, 1) * Vz(SIndex, 2)
    NormalV(SIndex, 3) = Vx(SIndex, 1) * Vy(SIndex, 2) - Vy(SIndex, 1) * Vx(SIndex, 2)

    DO K = 1, 3
        Vector(K) = NormalV(SIndex, K)
    END DO

    NV(Sindex) = SQRT(DOT_PRODUCT(Vector, Vector))

    ! Converts/Normalizes the normal vector to get the unit vector
    DO J = 1, 3
        NormalUV(SIndex, J) = Vector(J) / NV(SIndex)
    END DO

END SUBROUTINE SurfaceNormal

SUBROUTINE CalculateAreaSurfaces()
!******************************************************************************
!
!  PURPOSE:        Determine areas of the surfaces in the enclosure
!
!
!******************************************************************************

    IMPLICIT NONE
    INTEGER :: I, J, VStart, VEnd, IOS
    INTEGER, DIMENSION (:) :: VS(4)
    REAL(Prec2), DIMENSION(:) :: X(4), Y(4), Z(4)
    REAL(Prec2), ALLOCATABLE, DIMENSION(:) :: LR, LT
    REAL(Prec2) :: S
    REAL(Prec2), DIMENSION(:) :: VecA(3), VecB(3), VecD(3), VecC(3)
    REAL(Prec2) :: LenVecA, LenVecB, LenVecD, LenVecC, Theta1, Theta2

    !   LR            Length and width of a rectangular surface in the enclosure
    !   LT            The three sides of a triangular surface in the enclosure
    !   S             A parameter used to calculate area for triangular surfaces
    !                 using the Heron's formula s = (LT(1) + LT(2) + LT(3))/2
    !   VS            Vertices of a surface
    !   X, Y & Z      Are coordinates of a vertex


    !   Assign the surfaces their corresponding vertices and coordinates and
    !   and calculate areas of rectangular and triangular polygons

    ALLOCATE(LR(4), LT(3), STAT = IOS)

    ! Initialize
    S = 0

    IF(PolygonIndex(SIndex) == 4)THEN
        DO J = 1, 4
            VS(J) = SVertex(SIndex, J)
            X(J) = XS(VS(J))
            Y(J) = YS(VS(J))
            Z(J) = ZS(VS(J))
        END DO

        ! Compute the side lengths
        DO I = 1, 4
            IF (I .lt. 4) THEN
                LR(I) = SQRT((X(I + 1) - X(I))**2 + (Y(I + 1) - Y(I))**2 + (Z(I + 1) - Z(I))**2)
            ELSE
                LR(4) = SQRT((X(1) - X(4))**2 + (Y(1) - Y(4))**2 + (Z(1) - Z(4))**2)
            END IF
            S = S + LR(I)
        END DO

        ! Sum of side lengths divided by 2
        S = S / 2

        ! Determine side vectors
        ! Vector from vertex 1 to 2
        VStart = 1
        VEnd = 2
        VecA(1) = X(VEnd) - X(VStart)
        VecA(2) = Y(VEnd) - Y(VStart)
        VecA(3) = Z(VEnd) - Z(VStart)

        ! Vector from 1 to 4
        VStart = 1
        VEnd = 4
        VecB(1) = X(VEnd) - X(VStart)
        VecB(2) = Y(VEnd) - Y(VStart)
        VecB(3) = Z(VEnd) - Z(VStart)

        ! Vector from 3 to 2
        VStart = 3
        VEnd = 2
        VecD(1) = X(VEnd) - X(VStart)
        VecD(2) = Y(VEnd) - Y(VStart)
        VecD(3) = Z(VEnd) - Z(VStart)

        ! Vector from 3 to 4
        VStart = 3
        VEnd = 4
        VecC(1) = X(VEnd) - X(VStart)
        VecC(2) = Y(VEnd) - Y(VStart)
        VecC(3) = Z(VEnd) - Z(VStart)

        ! Compute vector magnatudes
        LenVecA = SQRT(VecA(1)**2 + VecA(2)**2 + VecA(3)**2)
        LenVecB = SQRT(VecB(1)**2 + VecB(2)**2 + VecB(3)**2)
        LenVecD = SQRT(VecD(1)**2 + VecD(2)**2 + VecD(3)**2)
        LenVecC = SQRT(VecC(1)**2 + VecC(2)**2 + VecC(3)**2)

        ! Compute two opposing angles
        Theta1 = ACOS(DOT_PRODUCT(VecA, VecB) / (LenVecA * LenVecB))
        Theta2 = ACOS(DOT_PRODUCT(VecD, VecC) / (LenVecD * LenVecC))

        ! Compute area using Bretschneider's formula
        Area(SIndex) = SQRT((S - LR(1)) * (S - LR(2)) * (S - LR(3)) * (S - LR(4)) - LR(1) * LR(2) * LR(3) * LR(4) * COS((Theta1 + Theta2) / 2)**2)
!
    ELSEIF(PolygonIndex(SIndex) == 3)THEN
        DO J = 1, 4
            VS(J) = SVertex(SIndex, J)
            IF(J < 4)THEN
                X(J) = XS(VS(J))
                Y(J) = YS(VS(J))
                Z(J) = ZS(VS(J))
            ELSEIF(J == 4)THEN
                X(4) = XS(VS(1))
                Y(4) = YS(VS(1))
                Z(4) = ZS(VS(1))
            ENDIF
        END DO

        DO J = 1, 3
            LT(J) = SQRT((X(J + 1) - X(J))**2 + (Y(J + 1) - Y(J))**2 + (Z(J + 1) - Z(J))**2)
        END DO

        S = (LT(1) + LT(2) + LT(3)) / 2
        Area(SIndex) = SQRT(S * (S - LT(1)) * (S - LT(2)) * (S - LT(3)))
    ENDIF
END SUBROUTINE CalculateAreaSurfaces

SUBROUTINE CrossProduct(Vec1, Vec2, Vec)
!******************************************************************************
!
!  PURPOSE:        Calculates the crossProduct of two vectors
!
!
!******************************************************************************

    REAL(Prec2) :: Vec1(3), Vec2(3), Vec(3)
    Vec(1) = Vec1(2) * Vec2(3) - Vec1(3) * Vec2(2)
    Vec(2) = Vec1(3) * Vec2(1) - Vec1(1) * Vec2(3)
    Vec(3) = Vec1(1) * Vec2(2) - Vec1(2) * Vec2(1)
END SUBROUTINE CrossProduct

Function Norm_V(V)
!******************************************************************************
!
!  PURPOSE:        Calculates the magnitude of a vector
!
!
!******************************************************************************
    IMPLICIT NONE
    REAL(Prec2) :: V(3), Norm_V
    !   V(3)        the vector whose magnitude is to be determined
    !   Norm_V      is the magnitude of the vector V

    Norm_V = 0.0d0
    Norm_V = SQRT(DOT_PRODUCT(V, V))
END Function Norm_V

SUBROUTINE AllocateAndInitArrays()
!******************************************************************************
!
!  PURPOSE:        Allocates the arrays
!
!
!******************************************************************************

    IMPLICIT NONE
    INTEGER :: I, J, IOS

    ALLOCATE(NAEnergy(NSurf, NSurf))
    ALLOCATE(TCOUNTA(NSurf), Area(NSurf), STAT = IOS)
    ALLOCATE(XLS(NSurf), YLS(NSurf), ZLS(NSurf), STAT = IOS)
    ALLOCATE(XP(NSurf, NSurf), YP(NSurf, NSurf), ZP(NSurf, NSurf), Intersection(NSurf, NSurf), STAT = IOS)
    ALLOCATE(Xo(NSurf), Yo(NSurf), Zo(NSurf), Intersects(NSurf), STAT = IOS)
    ALLOCATE (EmittedUV(NSurf, 3), STAT = IOS )

    NAEnergy = 0
    Area = 0
    TCOUNTA = 0
    XLS = 0
    YLS = 0
    ZLS = 0
    XP = 0
    YP = 0
    ZP = 0
    Intersection = 0
    Xo = 0
    Yo = 0
    Zo = 0
    EmittedUv = 0

END SUBROUTINE AllocateAndInitArrays

END MODULE EnclosureGeometry
