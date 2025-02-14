      subroutine dl_more(iter,nparm,dl_momentum,dl_EG_sq,dl_EG,deltap,parameters)

      implicit real*8 (a-h,o-z)
      character*20 dl_alg

      include 'mpif.h'

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'sr.h'

      common /sr_mat_n/ sr_o(MPARM,MCONF),sr_ho(MPARM,MCONF),obs(MOBS,MSTATES),s_diag(MPARM,MSTATES)
     &,s_ii_inv(MPARM),h_sr(MPARM),wtg(MCONF,MSTATES),elocal(MCONF,MSTATES),jfj,jefj,jhfj,nconf

      common /mpiconf/ idtask,nproc

      dimension deltap(*),dl_momentum(*),dl_EG_sq(*),dl_EG(*),parameters(*)

      call p2gtfd('optwf:sr_adiag',sr_adiag,0.01,1)
      call p2gtfd('optwf:sr_tau',sr_tau,0.02,1)

      call p2gtfd('optwf:dl_mom',dl_mom,0.0,1)
      call p2gtid('optwf:idl_flag',idl_flag,0,1)
      call p2gtad('optwf:dl_alg',dl_alg,'nag',1)

c we only need h_sr = - grad_parm E
      call sr_hs(nparm,sr_adiag)

      if(idtask.eq.0) then 
        call dl_iter(iter,nparm,dl_alg,dl_mom,sr_tau,dl_momentum,dl_EG_sq,dl_EG,deltap,parameters)
      endif

      call MPI_BCAST(deltap,nparm,MPI_REAL8,0,MPI_COMM_WORLD,ier)

      return
      end

ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
