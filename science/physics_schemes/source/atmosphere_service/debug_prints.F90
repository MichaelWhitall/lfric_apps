
MODULE debug_prints_mod

IMPLICIT NONE
SAVE

INTEGER, PARAMETER :: n_calls_max = 1000
INTEGER :: n_calls = 0
INTEGER :: array_int_sums(n_calls_max)
CHARACTER(LEN=200) :: array_names(n_calls_max)

REAL, ALLOCATABLE :: debug_work(:,:,:,:)

CONTAINS


SUBROUTINE debug_prints( nx, ny, nz, offx, offy, array, array_name )

IMPLICIT NONE

INTEGER, INTENT(IN) :: nx, ny, nz, offx, offy

REAL, INTENT(IN) :: array( 1-offx:nx+offx, 1-offy:ny+offy, nz )

CHARACTER(LEN=*), INTENT(IN) :: array_name

INTEGER, PARAMETER :: pos = 3 - INT( LOG10( EPSILON(array) ) )
REAL, PARAMETER :: irrat = SQRT(2.0)

CHARACTER(LEN=30) :: array_string

INTEGER :: array_int_k(nx,ny)
INTEGER :: array_int_sum_k(nz)

INTEGER :: i, j, k

n_calls = n_calls + 1

array_names(n_calls) = TRIM(ADJUSTL(array_name))

!$OMP PARALLEL DO DEFAULT(NONE) SCHEDULE(STATIC)                               &
!$OMP PRIVATE( i, j, k, array_string, array_int_k )                            &
!$OMP SHARED( nx, ny, nz, array, array_int_sum_k )
DO k = 1, nz
  DO j = 1, ny
    DO i = 1, nx
      WRITE(array_string,"(es30.23)") array(i,j,k) * irrat
      READ(array_string(pos:pos+2),"(I3)") array_int_k(i,j)
    END DO
  END DO
  array_int_sum_k(k) = SUM(array_int_k)
END DO
!$OMP END PARALLEL DO

array_int_sums(n_calls) = SUM(array_int_sum_k)

RETURN
END SUBROUTINE debug_prints


SUBROUTINE debug_prints_final()

USE UM_ParCore, ONLY: nproc, mype
USE umPrintMgr, ONLY: umprint, ummessage

IMPLICIT NONE

INTEGER :: istat
INTEGER :: i_call

!CALL gc_isum( n_calls, nproc, istat, array_int_sums(1:n_calls) )

IF ( mype==0 ) THEN
  DO i_call = 1, n_calls
    WRITE(ummessage,"(A,I16)") TRIM(ADJUSTL(array_names(i_call))),             &
                               array_int_sums(i_call)
    CALL umPrint(umMessage,src="CALC_GLOB_NORM")
  END DO
END IF

n_calls = 0

RETURN
END SUBROUTINE debug_prints_final


END MODULE debug_prints_mod
