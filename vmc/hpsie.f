      subroutine psie(iel,coord,psid,psij,ipass,iflag)
c Written by Claudia Filippi by modifying hpsi

      implicit real*8(a-h,o-z)
      character*12 mode

      include 'vmc.h'
      include 'pseudo.h'
      include 'force.h'
      include 'optjas.h'
      include 'optci.h'
      include 'mstates.h'

      parameter (MEXCIT=10)
c Calculates wave function

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr

      common /elec/ nup,ndn

      common /wfsec/ iwftype(MFORCE),iwf,nwftype

      common /contr2/ ijas,icusp,icusp2,isc,ianalyt_lap
     &,ifock,i3body,irewgt,iaver,istrch

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /velocity_jastrow/vj(3,MELEC),vjn(3,MELEC)

      common /multidet/ kref,numrep_det(MDET,2),irepcol_det(MELEC,MDET,2),ireporb_det(MELEC,MDET,2)
     & ,iwundet(MDET,2),iactv(2),ivirt(2)

      common /multislatern/ detn(MDET)
     &,orb(MORB),dorb(3,MORB),ddorb(MORB)

      common /estpsi/ detref(2),apsi(MSTATES),aref

      common /distance/ rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT),rvec_ee(3,MMAT_DIM2),r_ee(MMAT_DIM2)

      dimension coord(3,*),psid(*)

      iwf=iwftype(1)

      call distances(iel,coord)

      if(ianalyt_lap.eq.1) then
        call jastrowe(iel,coord,vjn,d2j,psij,iflag)
       else
        call fatal_error('HPSIE: numerical one-electron move not implemented')
      endif

c compute all determinants 
      call determinante(iel,x,rvec_en,r_en,iflag)

      if(detn(kref).eq.0.d0) then
        do 1 istate=1,nstates
   1      psid(istate)=0.d0
        return
      endif

      call multideterminante(iel)

c combine determinantal quantities to obtain trial wave function
      do 10 istate=1,nstates
   10   call determinante_psit(iel,psid(istate),istate)

      if(ipass.gt.2) then

        check_apsi_min=1.d+99
        do 20 istate=1,nstates
          apsi_now=apsi(istate)/(ipass-1)
          check_apsi=abs(psid(istate))/apsi_now

   20    check_apsi_min=min(check_apsi,check_apsi_min)

        aref_now=aref/(ipass-1)
        check_dref=abs(detn(kref))/aref_now

      endif

      return
      end
