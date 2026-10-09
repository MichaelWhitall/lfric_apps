!-----------------------------------------------------------------------------
! (c) Crown copyright 2024 Met Office. All rights reserved.
! The file LICENCE, distributed with this code, contains details of the terms
! under which the code may be used.
!-----------------------------------------------------------------------------
!> @brief calculate ratio of convective versus large-scale moisture sinks,
!> used to partition the surface precip diagnostics with comorph.
!>
module comorph_ppn_frac_kernel_mod

  use argument_mod, only : arg_type, GH_FIELD, GH_REAL, GH_READ, GH_WRITE,     &
                           ANY_DISCONTINUOUS_SPACE_1, DOMAIN
  use kernel_mod,   only : kernel_type

  implicit none

  private

  type, public, extends(kernel_type) :: comorph_ppn_frac_kernel_type
    private
    type(arg_type) :: meta_args(4) = (/                                        &
         ! ls_qw_sink
         arg_type(GH_FIELD, GH_REAL, GH_READ,  ANY_DISCONTINUOUS_SPACE_1),     &
         ! cv_qw_sink
         arg_type(GH_FIELD, GH_REAL, GH_READ,  ANY_DISCONTINUOUS_SPACE_1),     &
         ! ls_ppn_frac
         arg_type(GH_FIELD, GH_REAL, GH_WRITE, ANY_DISCONTINUOUS_SPACE_1),     &
         ! cv_ppn_frac
         arg_type(GH_FIELD, GH_REAL, GH_WRITE, ANY_DISCONTINUOUS_SPACE_1)      &
        /)
    integer :: operates_on = DOMAIN
  contains
    procedure, nopass :: comorph_ppn_frac_code
  end type

  public :: comorph_ppn_frac_code

contains

  !> @brief calculate ratio of convective versus large-scale moisture sinks,
  !> used to partition the surface precip diagnostics with comorph.
  !>
  !> @param[in]   nlayers      Number of layers (not used)
  !> @param[in]   seg_len      Number of points on segment
  !> @param[in]   ls_qw_sink   Moisture sink from large-scale microphysics
  !> @param[in]   cv_qw_sink   Moisture sink from parameterised convection
  !> @param[out]  ls_ppn_frac  Fraction of precip from large-scale microphysics
  !> @param[out]  cv_ppn_frac  Fraction of precip from parameterised convection
  !> @param[in]   ndf_2d       Number of DOFs per cell for 2D fields
  !> @param[in]   undf_2d      Number of unique DOFs for 2D fields
  !> @param[in]   map_2d       Dofmap for 2D fields
  
  subroutine comorph_ppn_frac_code( nlayers, seg_len,                          &
                                    ls_qw_sink, cv_qw_sink,                    &
                                    ls_ppn_frac, cv_ppn_frac,                  &
                                    ndf_2d, undf_2d, map_2d )

    use constants_mod, only: i_def, r_def

    implicit none

    ! Arguments
    integer(kind=i_def), intent(in) :: nlayers, seg_len,                       &
                                       ndf_2d, undf_2d, map_2d(ndf_2d,seg_len)
    real(kind=r_def), dimension(undf_2d), intent(in) ::                        &
                                          ls_qw_sink, cv_qw_sink
    real(kind=r_def), dimension(undf_2d), intent(out) ::                       &
                                          ls_ppn_frac, cv_ppn_frac

    ! Loop counter
    integer(kind=i_def) :: i

    do i = 1, seg_len
      if ( cv_qw_sink(map_2d(1,i)) > 0.0_r_def ) then
        cv_ppn_frac(map_2d(1,i)) = cv_qw_sink(map_2d(1,i))                     &
                               / ( cv_qw_sink(map_2d(1,i))                     &
                                 + ls_qw_sink(map_2d(1,i)) )
      else
        cv_ppn_frac(map_2d(1,i)) = 0.0_r_def
      end if
      ls_ppn_frac(map_2d(1,i)) = 1.0_r_def - cv_ppn_frac(map_2d(1,i))
    end do

  end subroutine comorph_ppn_frac_code

end module comorph_ppn_frac_kernel_mod
