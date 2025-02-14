      subroutine optx_jas_ci_reduce
c Written by Claudia Filippi

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optci.h'
      include 'mpif.h'

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      common /mix_jas_ci/ dj_o_ci(MPARMJ,MDET),dj_de_ci(MPARMJ,MDET),
     &de_o_ci(MPARMJ,MDET),dj_oe_ci(MPARMJ,MDET)

      dimension collect(MPARMJ,MDET)

      if(ioptjas.eq.0.or.ioptci.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      call mpi_reduce(dj_o_ci,collect,MPARMJ*nciterm
     &     ,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_bcast(collect,MPARMJ*nciterm
     &     ,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      do 10 i=1,nparmj
        do 10 j=1,nciterm
  10     dj_o_ci(i,j)=collect(i,j)

      call mpi_reduce(dj_de_ci,collect,MPARMJ*nciterm
     &     ,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_bcast(collect,MPARMJ*nciterm
     &     ,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      do 20 i=1,nparmj
        do 20 j=1,nciterm
  20     dj_de_ci(i,j)=collect(i,j)

      call mpi_reduce(de_o_ci,collect,MPARMJ*nciterm
     &     ,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_bcast(collect,MPARMJ*nciterm
     &     ,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      do 30 i=1,nparmj
        do 30 j=1,nciterm
  30     de_o_ci(i,j)=collect(i,j)

      call mpi_reduce(dj_oe_ci,collect,MPARMJ*nciterm
     &     ,mpi_double_precision,mpi_sum,0,MPI_COMM_WORLD,ierr)

      call mpi_bcast(collect,MPARMJ*nciterm
     &     ,mpi_double_precision,0,MPI_COMM_WORLD,ierr)

      do 40 i=1,nparmj
        do 40 j=1,nciterm
  40     dj_oe_ci(i,j)=collect(i,j)

      call mpi_barrier(MPI_COMM_WORLD,ierr)

      return
      end
