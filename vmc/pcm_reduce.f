      subroutine pcm_reduce

      implicit real*8(a-h,o-z)
      include 'mpif.h'
      include 'pcm.h'

      logical wid
      common /mpiconf/ idtask,nproc,wid

      dimension collect(MCHS)
 
      if(ipcm.eq.0) return

      call mpi_reduce(spcmcum,spcmcollect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(spcmcm2,spcm2collect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(vpcmcum,vpcmcollect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(vpcmcm2,vpcm2collect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(qopcm_cum,qopcmcollect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(qopcm_cm2,qopcm2collect,1
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_reduce(enfpcm_cum,collect,nchs
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      if(wid) then
        do 10 i=1,nchs
  10      enfpcm_cum(i)=collect(i)
       else
        do 15 i=1,nchs
  15      enfpcm_cum(i)=0
      endif

      call mpi_reduce(enfpcm_cm2,collect,nchs
     &,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      if(wid) then
        do 20 i=1,nchs
  20      enfpcm_cm2(i)=collect(i)
       else
        do 25 i=1,nchs
  25      enfpcm_cm2(i)=0
      endif

      call mpi_barrier(MPI_COMM_WORLD,ierr)

      if(wid) then
        spcmcum=spcmcollect
        spcmcm2=spcm2collect
        vpcmcum=vpcmcollect
        vpcmcm2=vpcm2collect
        qopcm_cum=qopcmcollect
        qopcm_cm2=qopcm2collect
       else
        spcmcum=0
        spcmcm2=0
        vpcmcum=0
        vpcmcm2=0
        qopcm_cum=0
        qopcm_cm2=0
      endif

      return
      end

      subroutine pcm_reduce_chvol

      implicit real*8(a-h,o-z)
      include 'mpif.h'
      include 'mpi_qmc.h'
      include 'pcm.h'

      logical wid
      common /mpiconf/ idtask,nproc,wid

      common /pcm_xv_new/ xv_new(3,MCHV)

      dimension nchv_proc(0:NPROCX),charge(NPROCX)
      dimension icount(0:NPROCX),idispl(0:NPROCX)
 
      if(ipcm.eq.0) return

      call mpi_allgather(nchv,1,mpi_integer,nchv_proc,1,mpi_integer,
     &  MPI_COMM_WORLD,ierr)

      nch=nchs
      do 1 i=0,nproc-1
   1    nch=nch+nchv_proc(i)
      if(nch.gt.MCHV) call fatal_error('PCM_REDUCE: increase MCHV')

c     call mpi_allgather(qvol,1,mpi_double_precision,charge,1,mpi_double_precision,
c    &  MPI_COMM_WORLD,ierr)
c     qvol=0
c     do 15 i=0,nproc-1
c 15    qvol=qvol+charge(i)

c     tmp=(1.0d0-fs)/nscv
c     qvol=tmp/nproc
      do 16 i=nchs+1,nch
  16    ch(i)=qvol
      
      write(6,*) ' *** pcm update *** ',nch-nchs,qvol

      idispl(0)=3*nchs
      icount(0)=3*nchv_proc(0)
      do 10 i=1,nproc-1
        icount(i)=3*nchv_proc(i)
        idispl(i)=idispl(i-1)+3*nchv_proc(i-1)
  10  continue
c     write(6,*) ' *** pcm update *** ',(icount(i),i=0,nproc-1)
c     write(6,*) ' *** pcm update *** ',(idispl(i),i=0,nproc-1)

      nchv3=3*nchv
      call mpi_allgatherv(xv_new,nchv3,mpi_double_precision,
     &  xpol,icount,idispl,mpi_double_precision,MPI_COMM_WORLD,ierr)

      return
      end
