      subroutine olbfgs_more(iter, nparm, deltap, parameters)
      use olbfgs, only: update_hessian, olbfgs_iteration

      implicit real*8 (a-h,o-z)
      character*20 dl_alg

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'sr.h'

      include 'mpif.h'

      common /sr_mat_n/ sr_o(MPARM,MCONF),sr_ho(MPARM,MCONF),obs(MOBS,MSTATES),s_diag(MPARM,MSTATES)
     &,s_ii_inv(MPARM),h_sr(MPARM),wtg(MCONF,MSTATES),elocal(MCONF,MSTATES),jfj,jefj,jhfj,nconf

      dimension deltap(*), parameters(*)

      real(kind=8), dimension(1), allocatable :: parameters_old(:)
      real(kind=8), dimension(1), allocatable :: parms_lbfgs(:)

      allocate(parameters_old(nparm))
      allocate(parms_lbfgs(nparm))

      parms_lbfgs = parameters(1:nparm)
      parameters_old = parms_lbfgs


c we only need h_sr = - grad_parm E
      call sr_hs(nparm,sr_adiag)

      call p2gtfd('optwf:sr_adiag',sr_adiag,0.01,1)
      call p2gtfd('optwf:sr_tau',sr_tau,0.02,1)

      if(idtask.eq.0) then 
c update stored Hessian approximation
        call update_hessian(parms_lbfgs, -h_sr)

c perform actual oLBFGS iteration
        call olbfgs_iteration(parms_lbfgs, -h_sr, sr_tau, iter)

        deltap(1:nparm) = parms_lbfgs - parameters_old
        parameters(1:nparm) = parameters(1:nparm) + deltap(1:nparm)
      end if

c Update parameter changes

      call MPI_BCAST(deltap,nparm,MPI_REAL8,0,MPI_COMM_WORLD,ier)

      deallocate(parameters_old)
      deallocate(parms_lbfgs)

      return
      end
