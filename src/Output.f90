MODULE Output

USE Global
USE EnclosureGeometry
USE EnergyBundleLocation
USE IntersectionEnergySurface
USE EnergyAbsorbedReflected
USE DistributionFactors
USE EnergyBalance

IMPLICIT NONE
CONTAINS

SUBROUTINE Progress(Surf, TotNumSurfs)
    ! Writes status bar
    ! Original source from here: https://software.intel.com/en-us/forums/intel-fortran-compiler-for-linux-and-mac-os-x/topic/270155

    IMPLICIT NONE
    INTEGER(KIND = 4) :: K, Surf, TotNumSurfs, PercentComplete
    CHARACTER(len = 17) :: bar="???% |          |"
    PercentComplete = FLOOR(100 * REAL(Surf) / REAL(TotNumSurfs))
    WRITE(unit = bar(1:3), fmt = "(i3)") PercentComplete
    DO K = 1, FLOOR(10 * REAL(Surf) / REAL(TotNumSurfs))
        bar(6 + K : 6 + K)="*"
    END DO
    ! print the progress bar.
    WRITE(*, fmt = "(a1,a1,a17)") '+', CHAR(13), bar
    RETURN
END SUBROUTINE progress

SUBROUTINE PrintViewFactorHeatFlux()
    !******************************************************************************
    !
    ! PURPOSE:          Prints View Factors, Radiation Heat Flux and Heat Transfer
    !                   Rate at Each Surface
    !
    !
    !******************************************************************************
    IMPLICIT NONE
    INTEGER        :: I, J, K, Index

    ! WRITE the Title of the Program and Output data
    WRITE(3, 101)'Monte Carlo Method', 'PURPOSE:', 'Calculates The View &
                 Factors Using Monte Carlo Method', 'and', 'The Net Radiation &
                 Heat Flux at Each Surface'
101 FORMAT(//, 15x, A30, ///, 14x, A25, //, 14x, A52, /, 36x, A3, /, 11x, A50, //)

    DO K = 1, NSurf
        WRITE(3, 1001)NAEnergy(K, :), TCOUNTA(K)
    END DO

1001 FORMAT(2x, 100(x, I8), I10)

     WRITE(3, 1002)
     WRITE(6, 1002)

1002 FORMAT(//)

     DO Index = 1, NSurf_cmb
        WRITE(3, 102)(RAD_D_F_cmb(Index, J), J = 1, NSurf_cmb)   ! Diffuse distribution factors
     END DO

    ! Write csv file for combined surface
302  FORMAT(f10.6, 100(',', f10.6))
    WRITE(12, 302)(Area_cmb(I), I = 1, NSurf_cmb)
    DO I = 1, NSurf_cmb
        WRITE(12, 302)(RAD_D_F_cmb(I, J), J = 1, NSurf_cmb)
    END DO
    WRITE(12, 302)(Emit_cmb(I), I = 1, NSurf_cmb)

    ! Writing the rest of the outputs for MCOutput.txt
102  FORMAT(4x, 100(2x, f10.6))

     WRITE(3, 103)'Index', 'SurfName', 'Temperature', 'Emissivity', 'Heat Flux', 'Heat Transfer Rate'

103  FORMAT(///, 8x, A5, 2x, A10, 6x, A12, 2x, A12, 4x, A12, 8x, A19)

     DO Index = 1, NSurf
        WRITE(3, 104)Index, SurfName(Index), TS(Index), Emit(Index), QFLUX(Index), Q(Index)
104     FORMAT(7x, I3, 8x, A12, 4x, F7.2, 8x, F5.2, 8x, ES12.3, 10x, ES12.3)
     END DO

     WRITE(*, 107)'Elapsed Time:', TIME2 - TIME1, 's'
     WRITE(3, 107)'Elapsed Time:', TIME2 - TIME1, 's'

107  FORMAT(//, 8x, A14, 1x, F14.2, x, A1)

    END SUBROUTINE PrintViewFactorHeatFlux
 END MODULE Output
