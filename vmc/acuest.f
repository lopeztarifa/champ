      subroutine acuest
c Written by Cyrus Umrigar, modified by Claudia Filippi
c routine to accumulate estimators for energy etc.

      implicit real*8(a-h,o-z)
      character*12 mode

      parameter (half=.5d0)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optci.h'
      include 'optci_cblk.h'
      include 'optorb.h'
      include 'optorb_cblk.h'
      include 'pseudo.h'

      common /forcepar/ deltot(MFORCE),nforce,istrech
      common /forcest/ fcum(MSTATES,MFORCE),fcm2(MSTATES,MFORCE)
      common /forcewt/ wsum(MSTATES,MFORCE),wcum(MSTATES,MFORCE)

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar
      common /contr3/ mode
      common /config/ xold(3,MELEC),xnew(3,MELEC),vold(3,MELEC)
     &,vnew(3,MELEC),psi2o(MSTATES,MFORCE),psi2n(MFORCE),eold(MSTATES,MFORCE),enew(MFORCE)
     &,peo(MSTATES),pen,tjfn,tjfo(MSTATES),psido(MSTATES),psijo
     &,rmino(MELEC),rminn(MELEC),rvmino(3,MELEC),rvminn(3,MELEC)
     &,rminon(MELEC),rminno(MELEC),rvminon(3,MELEC),rvminno(3,MELEC)
     &,nearesto(MELEC),nearestn(MELEC),delttn(MELEC)
      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc
      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad
      common /estsum/ esum1(MSTATES),esum(MSTATES,MFORCE),pesum(MSTATES),tpbsum(MSTATES),tjfsum(MSTATES),r2sum,acc
      common /estcum/ ecum1(MSTATES),ecum(MSTATES,MFORCE),pecum(MSTATES),tpbcum(MSTATES),tjfcum(MSTATES),r2cum,iblk
      common /est2cm/ ecm21(MSTATES),ecm2(MSTATES,MFORCE),pecm2(MSTATES),tpbcm2(MSTATES),tjfcm2(MSTATES),r2cm2
      common /estsig/ ecum1s(MSTATES),ecm21s(MSTATES)
      common /estpsi/ detref(2),apsi(MSTATES),aref
      common /step/try(nrad),suc(nrad),trunfb(nrad),rprob(nrad)
     &,ekin(nrad),ekin2(nrad)
      common /denupdn/ rprobup(nrad),rprobdn(nrad)
      common /distance/ rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT)
     &,r_en(MELEC,MCENT),rvec_ee(3,MMAT_DIM2),r_ee(MMAT_DIM2)
      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates
      common /multidet/ kref,numrep_det(MDET,2),irepcol_det(MELEC,MDET,2),ireporb_det(MELEC,MDET,2)
     & ,iwundet(MDET,2),iactv(2),ivirt(2)

      common /multislater/ detu(MDET),detd(MDET)

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm

      dimension xstrech(3,MELEC),enow(MSTATES,MFORCE)

c xsum = sum of values of x from metrop
c xnow = average of values of x from metrop
c xcum = accumulated sums of xnow
c xcm2 = accumulated sums of xnow**2

      dimension wtg(MSTATES)


c collect cumulative averages

      do 10 ifr=1,nforce
        do 10 istate=1,nstates
     
        enow(istate,ifr)=esum(istate,ifr)/wsum(istate,ifr)
        wcum(istate,ifr)=wcum(istate,ifr)+wsum(istate,ifr)
        ecum(istate,ifr)=ecum(istate,ifr)+esum(istate,ifr)
        ecm2(istate,ifr)=ecm2(istate,ifr)+esum(istate,ifr)*enow(istate,ifr)

        if(ifr.eq.1) then
          penow=pesum(istate)/wsum(istate,ifr)
          tpbnow=tpbsum(istate)/wsum(istate,ifr)
          tjfnow=tjfsum(istate)/wsum(istate,ifr)
          r2now=r2sum/(wsum(istate,ifr)*nelec)

          pecm2(istate)=pecm2(istate)+pesum(istate)*penow
          tpbcm2(istate)=tpbcm2(istate)+tpbsum(istate)*tpbnow
          tjfcm2(istate)=tjfcm2(istate)+tjfsum(istate)*tjfnow
          r2cm2=r2cm2+r2sum*r2now/nelec

          pecum(istate)=pecum(istate)+pesum(istate)
          tpbcum(istate)=tpbcum(istate)+tpbsum(istate)
          tjfcum(istate)=tjfcum(istate)+tjfsum(istate)
          r2cum=r2cum+r2sum/nelec

         else
          fcum(istate,ifr)=fcum(istate,ifr)+wsum(istate,1)*(enow(istate,ifr)-esum(istate,1)/wsum(istate,1))
          fcm2(istate,ifr)=fcm2(istate,ifr)+wsum(istate,1)*(enow(istate,ifr)-esum(istate,1)/wsum(istate,1))**2
        endif
   10 continue

c only called for ifr=1
      call optjas_cum(wsum(1,1),enow(1,1))
      call optorb_cum(wsum(1,1),esum(1,1))
      call optci_cum(wsum(1,1))
      call prop_cum(wsum(1,1))
      call pcm_cum(wsum(1,1))
      call mmpol_cum(wsum(1,1))
      call force_analy_cum(wsum(1,1),ecum(1,1)/wcum(1,1),wcum(1,1))

c zero out xsum variables for metrop

      do 25 istate=1,nstates
        do 20 ifr=1,nforce
          esum(istate,ifr)=0
  20      wsum(istate,ifr)=0
        pesum(istate)=0
        tpbsum(istate)=0
  25    tjfsum(istate)=0
      r2sum=0

      call prop_init(1)
      call optorb_init(1)
      call optci_init(1)
      call pcm_init(1)
      call mmpol_init(1)
      call force_analy_init(1)

      call acuest_reduce(enow)

      return
c-----------------------------------------------------------------------
      entry acues1(wtg)
c statistical fluctuations without blocking
      do 30 istate=1,nstates
        ecum1(istate)=ecum1(istate)+esum1(istate)*wtg(istate)
        ecm21(istate)=ecm21(istate)+esum1(istate)**2*wtg(istate)
        esum1(istate)=0
        
        apsi(istate)=apsi(istate)+dabs(psido(istate))
  30  continue
    
      aref=aref+dabs(detu(kref)*detd(kref))

      detref(1)=detref(1)+dlog10(dabs(detu(kref)))
      detref(2)=detref(2)+dlog10(dabs(detd(kref)))

      call acues1_reduce

      return
c-----------------------------------------------------------------------
      entry acusig(wtg)
c sigma evaluation
      do 40 istate=1,nstates
        ecum1s(istate)=ecum1s(istate)+esum1(istate)*wtg(istate)
        ecm21s(istate)=ecm21s(istate)+esum1(istate)**2*wtg(istate)
  40    esum1(istate)=0
      return
c-----------------------------------------------------------------------
      entry zerest

      call p2gtid('vmc:node_cutoff',node_cutoff,0,1)
      call p2gtfd('vmc:enode_cutoff',eps_node_cutoff,1.d-7,1)

c entry point to zero out all averages etc.
c the initial values of energy psi etc. is also calculated here
c although that really only needs to be done before the equil. blocks.

      iblk=0

c set quadrature points
      if(nloc.gt.0) call gesqua(nquad,xq,yq,zq,wq)

c zero out estimators
      acc=0
      do 50 istate=1,nstates
        pecum(istate)=0
        tpbcum(istate)=0
        tjfcum(istate)=0
        ecum1(istate)=0
        ecum1s(istate)=0

        pecm2(istate)=0
        tpbcm2(istate)=0
        tjfcm2(istate)=0
        ecm21(istate)=0
        ecm21s(istate)=0

        pesum(istate)=0
        tpbsum(istate)=0
        tjfsum(istate)=0

        apsi(istate)=0
  50  continue

      detref(1)=0
      detref(2)=0

      aref=0

      r2cm2=0
      r2cum=0
      r2sum=0

      call optjas_init
      call optci_init(0)
      call optorb_init(0)
      call optx_jas_orb_init
      call optx_jas_ci_init
      call optx_orb_ci_init

      call prop_init(0)
      call pcm_init(0)
      call mmpol_init(0)
      call force_analy_init(0)
      call efficiency_init

      do 65 ifr=1,nforce
        do 65 istate=1,nstates
          ecum(istate,ifr)=0
          ecm2(istate,ifr)=0
          wcum(istate,ifr)=0
          esum(istate,ifr)=0
          wsum(istate,ifr)=0
          fcum(istate,ifr)=0
   65     fcm2(istate,ifr)=0

c Zero out estimators for acceptance, force-bias trun., kin. en. and density
      do 70 i=1,nrad
        try(i)=0
        suc(i)=0
        trunfb(i)=0
        ekin(i)=0
        ekin2(i)=0
        rprobup(i)=0
        rprobdn(i)=0
   70   rprob(i)=0

c get nuclear potential energy
      call pot_nn(cent,znuc,iwctype,ncent,pecent)

c get wavefunction etc. at initial point

c secondary configs
c set n- and e-coords and n-n potentials before getting wavefn. etc.
      do 80 ifr=2,nforce
        call strech(xold,xstrech,ajacob,ifr,1)
        call hpsi(xstrech,psido,psijo,eold(1,ifr),0,ifr)
        do 80 istate=1,nstates
   80     psi2o(istate,ifr)=2*(dlog(dabs(psido(istate)))+psijo)+dlog(ajacob)

c primary config
c set n- and e-coords and n-n potentials before getting wavefn. etc.
      if(nforce.gt.1) call strech(xold,xstrech,ajacob,1,0)
      call hpsi(xold,psido,psijo,eold(1,1),0,1)

      do 82 istate=1,nstates
   82   psi2o(istate,1)=2*(dlog(dabs(psido(istate)))+psijo)

      if(iguiding.gt.0) then
        call determinant_psig(psido,psidg)
c rewrite psi2o if you are sampling guiding
        psi2o(1,1)=2*(dlog(dabs(psidg))+psijo)
      endif

      if(ipr.gt.1) then
        write(6,'(''psid, psidg='',2d12.4)') psido(1),psidg
        write(6,'(''psid2o='',f9.4)') psi2o(1,1)
      endif

      if(node_cutoff.gt.0) then
        do 83 jel=1,nelec
   83     call compute_determinante_grad(jel,psido,psido,vold(1,jel),1)
        call nodes_distance(vold,distance_node,1)
        rnorm_nodes=rnorm_nodes_num(distance_node,eps_node_cutoff)/distance_node

        psi2o(1,1)=psi2o(1,1)+2*dlog(rnorm_nodes)

        if(ipr.gt.1) then
          write(6,'(''distance_node='',d12.4)') distance_node
          write(6,'(''rnorm_nodes='',d12.4)') rnorm_nodes
          write(6,'(''psid2o_ncut='',f9.4)') psi2o(1,1)
          do 84 i=1,nelec
   84         write(6,'(''vd'',3e20.10)') (vold(k,i),k=1,3)
        endif
      endif

      if(ioptorb.gt.0) ns_current=0

      call prop_save
      call pcm_save
      call mmpol_save
      call optjas_save
      call optci_save
      call optorb_save
      call force_analy_save

c get interparticle distances
      call distances(0,xold)

      do 86 i=1,nelec
        rmino(i)=99.d9
        do 85 ic=1,ncent
          if(r_en(i,ic).lt.rmino(i)) then
            rmino(i)=r_en(i,ic)
            nearesto(i)=ic
          endif
   85     continue
        do 86  k=1,3
   86     rvmino(k,i)=rvec_en(k,i,nearesto(i))

      return
      end
