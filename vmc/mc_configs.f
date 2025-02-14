      subroutine mc_configs_start

      implicit real*8(a-h,o-z)

      include 'mpif.h'

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'

      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar
      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /config/ xold(3,MELEC),xnew(3,MELEC),vold(3,MELEC)
     &,vnew(3,MELEC),psi2o(MSTATES,MFORCE),psi2n(MFORCE),eold(MSTATES,MFORCE),enew(MFORCE)
     &,peo(MSTATES),pen,tjfn,tjfo(MSTATES),psido(MSTATES),psijo
     &,rmino(MELEC),rminn(MELEC),rvmino(3,MELEC),rvminn(3,MELEC)
     &,rminon(MELEC),rminno(MELEC),rvminon(3,MELEC),rvminno(3,MELEC)
     &,nearesto(MELEC),nearestn(MELEC),delttn(MELEC)
      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      logical wid
      common /mpiconf/ idtask,nproc,wid

      character*20 filename

      dimension irn(4)
      dimension nsite(MCENT)
      dimension istatus(MPI_STATUS_SIZE)

      dimension irn_temp(4)

c set the random number seed differently on each processor
c call to setrn must be in read_input since irn local there
      if(irstar.ne.1) then

c         if(idtask.ne.0) then
c          call mpi_isend(irn,4,mpi_integer,0,1,MPI_COMM_WORLD,irequest,ierr)
c         else
c          write(6,*) 0, irn
c          do 1 id=1,nproc-1
c            call mpi_recv(irn_temp,4,mpi_integer,id,1,MPI_COMM_WORLD,istatus,ierr)
c            write(6,*) id, irn_temp
c   1      continue
c         endif

        if(nproc.gt.1) then
          do 5 id=1,(3*nelec)*idtask
    5       rnd=rannyu(0)
          call savern(irn)
          do 6 i=1,4
    6       irn(i)=mod(irn(i)+int(rannyu(0)*idtask*9999),9999)
          call setrn(irn)
        endif

c check sites flag if one gets initial configuration from sites routine
        if (isite.eq.1) goto 20
        open(unit=9,err=20,file='mc_configs_start')
        rewind 9
        do 10 id=0,idtask
   10     read(9,*,end=20,err=20) ((xold(k,i),k=1,3),i=1,nelec)
        write(6,'(/,''initial configuration from unit 9'')')
        goto 40

   20   call p2gtid('startend:icharged_atom',icharged_atom,0,1) 
	ntotal_sites=0
        do 25 i=1,ncent
   25     ntotal_sites=ntotal_sites+int(znuc(iwctype(i))+0.5d0)
        icharge_system=ntotal_sites-nelec

        l=0
        do 30 i=1,ncent
          nsite(i)=int(znuc(iwctype(i))+0.5d0)
          if (icharged_atom.eq.i) then
            nsite(i)=int(znuc(iwctype(i))+0.5d0)-icharge_system
	    if (nsite(i).lt.0) call fatal_error('MC_CONFIG: error in icharged_atom')
	  endif
          l=l+nsite(i)
          if (l.gt.nelec) then
            nsite(i)=nsite(i)-(l-nelec)
            l=nelec
          endif
   30   continue
        if (l.lt.nelec) nsite(1)=nsite(1)+(nelec-l)

        call sites(xold,nelec,nsite)
        open(unit=9,file='mc_configs_start')
        rewind 9
        write(6,'(/,''initial configuration from sites'')')
   40   continue

c If we are moving one electron at a time, then we need to initialize
c xnew, since only the first electron gets initialized in metrop
        do 50 i=1,nelec
          do 50 k=1,3
   50       xnew(k,i)=xold(k,i)
      endif

c If nconf_new > 0 then we want to dump configurations for a future
c optimization or dmc calculation. So figure out how often we need to write a
c configuration to produce nconf_new configurations. If nconf_new = 0
c then set up so no configurations are written.
      if (nconf_new.gt.0) then
        if(idtask.lt.10) then
          write(filename,'(i1)') idtask
         elseif(idtask.lt.100) then
          write(filename,'(i2)') idtask
         elseif(idtask.lt.1000) then
          write(filename,'(i3)') idtask
         else
          write(filename,'(i4)') idtask
        endif
        filename='mc_configs_new'//filename(1:index(filename,' ')-1)
        open(unit=7,form='formatted',file=filename)
        rewind 7
      endif

      call pcm_qvol(nproc)

      return

c-----------------------------------------------------------------------
      entry mc_configs_write

      if(idtask.ne.0) then
        call mpi_send(xold,3*nelec,mpi_double_precision,0
     &  ,1,MPI_COMM_WORLD,ierr)
c    &  ,1,MPI_COMM_WORLD,irequest,ierr)
       else
        rewind 9
        write(9,*) ((xold(ic,i),ic=1,3),i=1,nelec)
        do 60 id=1,nproc-1
          call mpi_recv(xnew,3*nelec,mpi_double_precision,id
     &    ,1,MPI_COMM_WORLD,istatus,ierr)
   60     write(9,*) ((xnew(ic,i),ic=1,3),i=1,nelec)
      endif
      close(9)

c reduce cum1 estimates, density and related quantities
      call fin_reduce

      return
      end
