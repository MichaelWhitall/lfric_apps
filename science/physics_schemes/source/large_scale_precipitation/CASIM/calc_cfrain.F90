! *****************************COPYRIGHT*******************************
! (C) Crown copyright Met Office. All rights reserved.
! For further details please refer to the file COPYRIGHT.txt
! which you should have received as part of this distribution.
! *****************************COPYRIGHT*******************************
!
! Code Owner: Please refer to the UM file CodeOwners.txt
! This file belongs in section: large_scale_precipitation
module calc_cfrain_mod

IMPLICIT NONE

CONTAINS

SUBROUTINE calc_cfrain( nlayers,                                               &
                        qc_casim, qi_casim, qs_casim, qr_casim, qg_casim,      &
                        cfliq_casim, cfice_casim, precfrac_casim,              &
                        cfrain_casim, cfgr_casim )

use variable_precision, only: wp

implicit none

! Number of model-levels
integer, intent(in) :: nlayers

! Condensate species mixing-ratios on input to CASIM
real(kind=wp), dimension(nlayers), intent(in) :: qc_casim, qi_casim, qs_casim, &
                                                 qr_casim, qg_casim

! Ice and liquid cloud-fractions, and prognostic precip fraction
real(kind=wp), dimension(nlayers), intent(in) :: cfliq_casim, cfice_casim,     &
                                                 precfrac_casim

! Rain and graupel fractions to be calculated
real(kind=wp), dimension(nlayers), intent(out) :: cfrain_casim, cfgr_casim

! Vertical integrals of 1/sqrt(fraction) and condensate mass
real(kind=wp) :: int_r_sq_f, int_mass

! Precip and cloud masses at current point
real(kind=wp) :: mass_pre, mass_cl, mass_ci

! Loop counter
INTEGER :: k

! Miniscule number for check to avoid div-by-zero
real(kind=wp), PARAMETER :: min_float = TINY(mass_pre)


! Initialise integrals to zero
int_mass = 0.0_wp
int_r_sq_f = 0.0_wp

! Vertically-integrate downwards computing mass-weighted mean of 1/sqrt(frac)
! on all levels above the current height
DO k = nlayers, 1, -1
  mass_pre = qr_casim(k) + qg_casim(k)
  mass_cl  = 0.1 * qc_casim(k)
  mass_ci  = 0.1 * ( qi_casim(k) + qs_casim(k) )
  int_mass = int_mass + mass_pre + mass_cl + mass_ci
  int_r_sq_f = int_r_sq_f                                                      &
             + mass_pre / MAX( SQRT(precfrac_casim(k)), min_float )            &
             + mass_cl  / MAX( SQRT(cfliq_casim(k)), min_float )               &
             + mass_ci  / MAX( SQRT(cfice_casim(k)), min_float )
  ! 1/sqrt(frac) = int( m/sqrt(frac) ) / int( m )
  ! => frac = ( int( m ) / int( m/sqrt(frac) ) )**2
  cfrain_casim(k) = ( int_mass / MAX( int_r_sq_f, min_float ) )**2
END DO

! Set graupel fraction = rain fraction
do k = 1, nlayers
  cfgr_casim(k) = cfrain_casim(k)
end do


return
end SUBROUTINE calc_cfrain

end module calc_cfrain_mod
