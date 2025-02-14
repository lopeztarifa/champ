      subroutine vmc
c Written by Cyrus Umrigar and Claudia Filippi

c Program to do variational Monte Carlo calculations 
c on atoms and molecules.
c Various types of Metropolis moves can be done, including a few
c versions of directed Metropolis in spherical polar coordinates.
c Also, one or all electrons can be moved at once.
c Currently this program contains
c 1s, 2s, 2p, 3s, 3p, 3d, 4s,  and 4p  Slater basis states.
c and sa, pa, da asymptotic functions

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'basis.h'
      include 'numbas.h'
      include 'pseudo.h'

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar
      common /elec/ nup,ndn
      common /config/ xold(3,MELEC),xnew(3,MELEC),vold(3,MELEC)
     &,vnew(3,MELEC),psi2o(MSTATES,MFORCE),psi2n(MFORCE),eold(MSTATES,MFORCE),enew(MFORCE)
     &,peo(MSTATES),pen,tjfn,tjfo(MSTATES),psido(MSTATES),psijo
     &,rmino(MELEC),rminn(MELEC),rvmino(3,MELEC),rvminn(3,MELEC)
     &,rminon(MELEC),rminno(MELEC),rvminon(3,MELEC),rvminno(3,MELEC)
     &,nearesto(MELEC),nearestn(MELEC),delttn(MELEC)
      common /coefs/ coef(MBASIS,MORB,MWF),nbasis,norb
      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      common /jaspar/ nspin1,nspin2,sspin,sspinn,is
      common /jaspar1/ cjas1(MWF),cjas2(MWF)
      common /jaspar2/ a1(83,3,MWF),a2(83,3,MWF)
      common /jaspar3/ a(MORDJ1,MWF),b(MORDJ1,2,MWF),c(83,MCTYPE,MWF)
     &,fck(15,MCTYPE,MWF),scalek(MWF),nord
      common /jaspar4/ a4(MORDJ1,MCTYPE,MWF),norda,nordb,nordc
      common /rnyucm/ m1,m2,m3,m4,l1,l2,l3,l4
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc
      common /forcepar/ deltot(MFORCE),nforce,istrech
      common /wfsec/ iwftype(MFORCE),iwf,nwftype

      character*25 fmt

c common block variables:

c   /const/
c        nelec  = number of electrons
c        pi     = 3.14159...
c        hb     = hbar**2/(2m)
c        delta  = side of box in which metropolis steps are made
c        deltai = 1/delta
c        fbias  = force bias parameter
c   /contrl/
c        nstep  = number of metropolis steps/block
c        nblk   = number of blocks od nstep steps after the
c                equilibrium steps
c        nblkeq = number of equilibrium blocks
c        nconf  = target number of mc configurations (dmc only)
c        nconf_new = number of mc configurations generated for optim and dmc
c        idump  =  1 dump out stuff for a restart
c        irstar =  1 pick up stuff for a restart
c   /config/
c        xold   = current position of the electrons
c        xnew   = new position after a trial move
c        vold   = grad(psi)/psi at current position
c        vnew   = same after trial move
c        psi2o  = psi**2 at current position
c        psi2n  = same after trial move
c        eold   = local energy at current position
c        enew   = same after trial move
c        peo    = local potential at current position
c        pen    = same after trial move
c        tjfo   = Jackson Feenberg kinetic energy at current position
c        tjfn   = same after trial move
c        psido  = determinantal part of wave function
c        psijo  = log(Jastrow)
c   /coefs/
c        coef   = read in coefficients of the basis functions
c                 to get the molecular orbitals used in determinant
c        nbasis = number of basis functions read in
c   /dets/
c        cdet   = coefficients of the determinants
c        ndet   = number of determinants of molecular orbitals
c                 used
c        nup    = number of up spin electrons
c        ndn    = number of down spin electrons
c   /jaspar/
c        Jastrow function is dexp(cjas1*rij/(1+cjas2*rij)) if ijas=1

      if(nforce.gt.1) then
c force parameters
        call setup_force
       else
        nwftype=1
        iwftype(1)=1
      endif

c initialize the walker configuration
      call mc_configs_start
      if (nconf_new.eq.0) then
        ngfmc=2*nstep*nblk
       else
        ngfmc=(nstep*nblk+nconf_new-1)/nconf_new
      endif

c zero out estimators and averages
      if (irstar.ne.1) call zerest

c check if restart flag is on. If so then read input from
c dumped data to restart

      if (irstar.eq.1) then
        open(10,err=401,form='unformatted',file='restart_vmc')
        goto 402
  401   call fatal_error('VMC: restart_vmc empty, not able to restart')
  402   rewind 10
        call startr
        close(10)
      endif

c get initial value of cpu time
      call my_second(0,'begin ')

c if there are equilibrium steps to take, do them here
c skip equilibrium steps if restart run
c imetro = 6 spherical-polar with slater T
      if (nblkeq.ge.1.and.irstar.ne.1) then
        l=0
        do 420 i=1,nblkeq
          do 410 j=1,nstep
            l=l+1
            if (nloc.gt.0) call rotqua
            call metrop6(l,0)
  410     continue
  420   call acuest

c       Equilibration steps done. Zero out estimators again.
        call my_second(2,'equilb')
        call zerest
      endif

c now do averaging steps

      l=0
      do 440 i=1,nblk
        do 430 j=1,nstep
        l=l+1
        if (nloc.gt.0) call rotqua
        call metrop6(l,1)

c write out configuration for optimization/dmc/gfmc here
        if (mod(l,ngfmc).eq.0 .or. ngfmc.eq.1) then
          if(3*nelec.lt.100) then
           write(fmt,'(a1,i2,a21)')'(',3*nelec,'f13.8,i3,d12.4,f12.5)'
          else
           write(fmt,'(a1,i3,a21)')'(',3*nelec,'f13.8,i3,d12.4,f12.5)'
          endif
          write(7,fmt) ((xold(ii,jj),ii=1,3),jj=1,nelec),
     &    int(sign(1.d0,psido(1))),log(dabs(psido(1)))+psijo,eold(1,1)
        endif
  430   continue
  440 call acuest

      call my_second(2,'all   ')

c write out last configuration to mc_configs_start
c call fin_reduce to write out additional files for efpci, embedding etc.
c collected over all the run and to reduce cum1 in mpi version 
      call mc_configs_write

c print out final results
      call finwrt

c if dump flag is on then dump out data for a restart
      if (idump.eq.1) then
        open(10,form='unformatted',file='restart_vmc')
        rewind 10
        call dumper
        close(10)
      endif
      if(nconf_new.ne.0) close(7)

      return
      end
