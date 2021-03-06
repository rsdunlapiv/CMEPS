module med_internalstate_mod

  !-----------------------------------------------------------------------------
  ! Mediator Internal State Datatype.
  !-----------------------------------------------------------------------------

  use ESMF         , only : ESMF_RouteHandle, ESMF_FieldBundle, ESMF_State, ESMF_Field
  use ESMF         , only : ESMF_VM
  use esmFlds      , only : ncomps, nmappers
  use med_kind_mod , only : CX=>SHR_KIND_CX, CS=>SHR_KIND_CS, CL=>SHR_KIND_CL, R8=>SHR_KIND_R8

  implicit none
  private

  integer, public :: logunit            ! logunit for mediator log output
  integer, public :: diagunit           ! diagunit for budget output (med master only)
  integer, public :: loglevel           ! loglevel for mediator log output
  logical, public :: mastertask=.false. ! is this the mastertask
  integer, public :: med_id             ! needed currently in med_io_mod and set in esm.F90

  ! Active coupling definitions (will be initialize in med.F90)
  logical, public :: med_coupling_allowed(ncomps, ncomps)

  type, public ::  mesh_info_type
     real(r8), pointer :: areas(:) => null()
     real(r8), pointer :: lats(:) => null()
     real(r8), pointer :: lons(:) => null()
  end type mesh_info_type

  type, public :: packed_data_type
     integer, allocatable :: fldindex(:) ! size of number of packed fields
     character(len=CS)    :: mapnorm     ! normalization for packed field
     type(ESMF_Field)     :: field_src    ! packed sourced field
     type(ESMF_Field)     :: field_dst    ! packed destination field
     type(ESMF_Field)     :: field_fracsrc
     type(ESMF_Field)     :: field_fracdst
  end type packed_data_type

  ! private internal state to keep instance data
  type InternalStateStruct

    ! NState_Imp and NState_Exp are the standard NUOPC coupling datatypes
    ! FBImp and FBExp are the internal mediator datatypes
    ! NState_Exp(n) = FBExp(n), copied in the connector prep phase
    ! FBImp(n,n) = NState_Imp(n), copied in connector post phase
    ! FBImp(n,k) is the FBImp(n,n) interpolated to grid k
    ! RH(n,k,m) is a RH from grid n to grid k, map type m

    ! Present/Active logical flags
    logical                :: comp_present(ncomps)               ! comp present flag
    logical                :: med_coupling_active(ncomps,ncomps) ! computes the active coupling

    ! Mediator vm
    type(ESMF_VM)          :: vm

    ! Global nx,ny dimensions of input arrays (needed for mediator history output)
    integer                :: nx(ncomps), ny(ncomps)

    ! Import/Export Scalars
    character(len=CL)      :: flds_scalar_name = ''
    integer                :: flds_scalar_num = 0
    integer                :: flds_scalar_index_nx = 0
    integer                :: flds_scalar_index_ny = 0
    integer                :: flds_scalar_index_nextsw_cday = 0
    integer                :: flds_scalar_index_precip_factor = 0
    real(r8)               :: flds_scalar_precip_factor = 1._r8  ! actual value of precip factor from ocn

    ! Import/export States and field bundles (the field bundles have the scalar fields removed)
    type(ESMF_State)       :: NStateImp(ncomps)                  ! Import data from various component, on their grid
    type(ESMF_State)       :: NStateExp(ncomps)                  ! Export data to various component, on their grid
    type(ESMF_FieldBundle) :: FBImp(ncomps,ncomps)               ! Import data from various components interpolated to various grids
    type(ESMF_FieldBundle) :: FBExp(ncomps)                      ! Export data for various components, on their grid

    ! Mediator field bundles
    type(ESMF_FieldBundle) :: FBMed_ocnalb_o                     ! Ocn albedo on ocn grid
    type(ESMF_FieldBundle) :: FBMed_ocnalb_a                     ! Ocn albedo on atm grid
    type(packed_data_type) :: packed_data_ocnalb_o2a(nmappers)   ! packed data for mapping ocn->atm
    type(ESMF_FieldBundle) :: FBMed_aoflux_o                     ! Ocn/Atm flux fields on ocn grid
    type(ESMF_FieldBundle) :: FBMed_aoflux_a                     ! Ocn/Atm flux fields on atm grid
    type(packed_data_type) :: packed_data_aoflux_o2a(nmappers)   ! packed data for mapping ocn->atm

    ! Mapping
    type(ESMF_RouteHandle) :: RH(ncomps,ncomps,nmappers)            ! Routehandles for pairs of components and different mappers
    type(ESMF_Field)       :: field_NormOne(ncomps,ncomps,nmappers) ! Unity static normalization
    type(packed_data_type) :: packed_data(ncomps,ncomps,nmappers)   ! Packed data structure needed to efficiently map field bundles

    ! Fractions
    type(ESMF_FieldBundle) :: FBfrac(ncomps)                     ! Fraction data for various components, on their grid

    ! Accumulators for export field bundles
    type(ESMF_FieldBundle) :: FBExpAccum(ncomps)                 ! Accumulator for various components export on their grid
    integer                :: FBExpAccumCnt(ncomps)              ! Accumulator counter for each FBExpAccum
    logical                :: FBExpAccumFlag(ncomps) = .false.   ! Accumulator flag, if true accumulation was done

    ! Accumulators for import field bundles
    type(ESMF_FieldBundle) :: FBImpAccum(ncomps,ncomps)          ! Accumulator for various components import
    integer                :: FBImpAccumCnt(ncomps)              ! Accumulator counter for each FBImpAccum

    ! Component Mesh info
    type(mesh_info_type)   :: mesh_info(ncomps)

 end type InternalStateStruct

 type, public :: InternalState
    type(InternalStateStruct), pointer :: wrap
 end type InternalState

end module med_internalstate_mod
