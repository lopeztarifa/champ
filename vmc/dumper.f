      subroutine dumper
c MPI version created by Claudia Filippi starting from serial version
c routine to pick up and dump everything needed to restart
c job where it left off

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'pseudo.h'
      include 'mpi_qmc.h'
      include 'mpif.h'

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar
      common /forcepar/ deltot(MFORCE),nforce,istrech
      common /config/ xold(3,MELEC),xnew(3,MELEC),vold(3,MELEC)
     &,vnew(3,MELEC),psi2o(MSTATES,MFORCE),psi2n(MFORCE),eold(MSTATES,MFORCE),enew(MFORCE)
     &,peo(MSTATES),pen,tjfn,tjfo(MSTATES),psido(MSTATES),psijo
     &,rmino(MELEC),rminn(MELEC),rvmino(3,MELEC),rvminn(3,MELEC)
     &,rminon(MELEC),rminno(MELEC),rvminon(3,MELEC),rvminno(3,MELEC)
     &,nearesto(MELEC),nearestn(MELEC),delttn(MELEC)
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc
      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad
      common /estsum/ esum1(MSTATES),esum(MSTATES,MFORCE),pesum(MSTATES),tpbsum(MSTATES),tjfsum(MSTATES),r2sum,acc
      common /estcum/ ecum1(MSTATES),ecum(MSTATES,MFORCE),pecum(MSTATES),tpbcum(MSTATES),tjfcum(MSTATES),r2cum,iblk
      common /est2cm/ ecm21(MSTATES),ecm2(MSTATES,MFORCE),pecm2(MSTATES),tpbcm2(MSTATES),tjfcm2(MSTATES),r2cm2
      common /estsig/ ecum1s(MSTATES),ecm21s(MSTATES)
      common /forcest/ fcum(MSTATES,MFORCE),fcm2(MSTATES,MFORCE)
      common /forcewt/ wsum(MSTATES,MFORCE),wcum(MSTATES,MFORCE)
      common /step/try(nrad),suc(nrad),trunfb(nrad),rprob(nrad),
     &ekin(nrad),ekin2(nrad)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      logical wid
      common /mpiconf/ idtask,nproc,wid

      dimension irn(4,0:nprocx),istatus(MPI_STATUS_SIZE)
      dimension irn_tmp(4,0:nprocx)
      dimension ircounts(0:nprocx),idispls(0:nprocx)

      rewind 10

      do 10 i=0,nproc-1
        ircounts(i)=4
   10   idispls(i)=i*4
      idispls(nproc)=4*nproc
      nscounts=ircounts(idtask)

      call savern(irn(1,idtask))

      call mpi_gatherv(irn(1,idtask),nscounts,mpi_integer
     &,irn_tmp,ircounts,idispls,mpi_integer,0,MPI_COMM_WORLD,ierr)

      if(idtask.ne.0) then
        call mpi_send(xold,3*nelec,mpi_double_precision,0
     &  ,1,MPI_COMM_WORLD,ierr)
c    &  ,1,MPI_COMM_WORLD,irequest,ierr)
        call mpi_send(xq,nquad,mpi_double_precision,0
     &  ,2,MPI_COMM_WORLD,ierr)
c    &  ,2,MPI_COMM_WORLD,irequest,ierr)
        call mpi_send(yq,nquad,mpi_double_precision,0
     &  ,3,MPI_COMM_WORLD,ierr)
c    &  ,3,MPI_COMM_WORLD,irequest,ierr)
        call mpi_send(zq,nquad,mpi_double_precision,0
     &  ,4,MPI_COMM_WORLD,ierr)
c    &  ,4,MPI_COMM_WORLD,irequest,ierr)
       else
        write(10) nproc
        write(10) ((irn_tmp(i,j),i=1,4),j=0,nproc-1)
        write(10) nelec,nforce,nloc
        write(10) ((xold(k,i),k=1,3),i=1,nelec)
        if(nloc.gt.0) write(10) nquad,(xq(i),yq(i),zq(i),wq(i),i=1,nquad)
        do 20 id=1,nproc-1
          call mpi_recv(xold,3*nelec,mpi_double_precision,id
     &    ,1,MPI_COMM_WORLD,istatus,ierr)
          call mpi_recv(xq,nquad,mpi_double_precision,id
     &    ,2,MPI_COMM_WORLD,istatus,ierr)
          call mpi_recv(yq,nquad,mpi_double_precision,id
     &    ,3,MPI_COMM_WORLD,istatus,ierr)
          call mpi_recv(zq,nquad,mpi_double_precision,id
     &    ,4,MPI_COMM_WORLD,istatus,ierr)
          write(10) ((xold(k,i),k=1,3),i=1,nelec)
   20     if(nloc.gt.0) write(10) nquad,(xq(i),yq(i),zq(i),wq(i),i=1,nquad)
      endif

      call mpi_barrier(MPI_COMM_WORLD,ierr)

      if(.not.wid) return

      call dumper_more

      return

c-----------------------------------------------------------------------
      entry startr

      write(6,'(1x,''attempting restart from unit 10'')')

      rewind 10
      read(10) nproco
      if(nproco.ne.nproc) write(6,'(''Warning: different number of processors'',/
     & ,9x,''old number of processors'',i3,/,9x,''continuing with'',i3,'' processors'')') 
     & nproco,nproc
      read(10) ((irn(i,j),i=1,4),j=0,nproco-1)
      if(idtask.le.nproco-1) call setrn(irn(1,idtask))
      read(10) nelecx,nforcex,nlocx
      if (nelecx.ne.nelec) call fatal_error('STARTR: nelec')
      if (nforcex.ne.nforce) call fatal_error('STARTR: nforce')
      if (nlocx.ne.nloc) call fatal_error('STARTR: nloc')
      if(idtask.le.nproco-1) then
        do 30 id=0,idtask
          read(10) ((xold(k,i),k=1,3),i=1,nelec)
   30     if(nloc.gt.0) read(10) nqx,(xq(i),yq(i),zq(i),wq(i),i=1,nqx)
        if(nqx.ne.nquad) call fatal_error('STARTR: nquad')
        do 40 id=idtask+1,nproco-1
          read(10) (x_id,i=1,3*nelec)
   40     if(nloc.gt.0) read(10) nq_id,(xq_id,yq_id,zq_id,wq_id,i=1,nqd_id)
       else
        do 50 id=0,nproco-1
          read(10) (x_id,i=1,3*nelec)
   50     if(nloc.gt.0) read(10) nq_id,(xq_id,yq_id,zq_id,wq_id,i=1,nqd_id)
      endif

      if(nproc.gt.nproco) then
        if(idtask.le.nproco-1) then
          do 60 idget=nproco,nproc-1
c xold from idtask to idget
   60       if(idtask.eq.mod(idget,nproco)) 
     &      call mpi_send(xold,3*nelec,mpi_double_precision,idget
     &      ,idget,MPI_COMM_WORLD,ierr)
c    &      ,idget,MPI_COMM_WORLD,irequest,ierr)
         else
          do 70 id=1,(3*nelec)*idtask
   70       rnd=rannyu(0)
          idfrom=mod(idtask,nproco)
c xold from idfrom to idtask
          call mpi_recv(xold,3*nelec,mpi_double_precision,idfrom
     &    ,idtask,MPI_COMM_WORLD,istatus,ierr)
        endif
      endif

      call startr_more

      if (wid) return

      acc=0

      r2cum=0
      r2cm2=0
      do 80 istate=1,nstates

      pecum(istate)=0
      tpbcum(istate)=0
      tjfcum(istate)=0

      pecm2(istate)=0
      tpbcm2(istate)=0
      tjfcm2(istate)=0

      ecum1(istate)=0
      ecum1s(istate)=0
      ecm21(istate)=0
      ecm21s(istate)=0

      do 80 ifr=1,nforce
        ecum(istate,ifr)=0
        ecm2(istate,ifr)=0
        wcum(istate,ifr)=0
        fcum(istate,ifr)=0
   80   fcm2(istate,ifr)=0

      do 90 i=1,nrad
        try(i)=0
        suc(i)=0
        trunfb(i)=0
        ekin(i)=0
        ekin2(i)=0
   90   rprob(i)=0

      call optjas_init
      call optorb_init(0)
      call optci_init(0)
      call prop_init(0)
      call pcm_init(0)
      call mmpol_init(0)
      call force_analy_init(0)
      call efficiency_init

      end
