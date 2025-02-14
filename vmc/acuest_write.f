      subroutine acuest_write(enow,nproc)
c Written by Claudia Filippi
c routine to write out estimators for energy etc.

      implicit real*8(a-h,o-z)
      character*12 mode

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'pseudo.h'

      common /contr3/ mode
      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar
      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /forcepar/ deltot(MFORCE),nforce,istrech
      common /forcest/ fcum(MSTATES,MFORCE),fcm2(MSTATES,MFORCE)
      common /forcewt/ wsum(MSTATES,MFORCE),wcum(MSTATES,MFORCE)

      common /estsum/ esum1(MSTATES),esum(MSTATES,MFORCE),pesum(MSTATES),tpbsum(MSTATES),tjfsum(MSTATES),r2sum,acc
      common /estcum/ ecum1(MSTATES),ecum(MSTATES,MFORCE),pecum(MSTATES),tpbcum(MSTATES),tjfcum(MSTATES),r2cum,iblk
      common /est2cm/ ecm21(MSTATES),ecm2(MSTATES,MFORCE),pecm2(MSTATES),tpbcm2(MSTATES),tjfcm2(MSTATES),r2cm2

      dimension enow(MSTATES,MFORCE)

c statement function for error calculation
      err(x,x2,j,i)=dsqrt(abs(x2/wcum(j,i)-(x/wcum(j,i))**2)/iblk)

c xave = current average value of x
c xerr = current error of x

c write out header first time

      if (iblk.eq.nproc) write(6,'(t5,''enow'',t15,''eave'',t21,''(eerr )''
     &,t32,''peave'',t38,''(peerr)'',t49,''tpbave'',t55,''(tpberr''
     &,t66,''tjfave'',t72,''(tjferr'',t83,''fave'',t97,''(ferr)''
     &,t108,''accept'',t119,''iter'')')

c write out current values of averages
      denom=dfloat(nstep*iblk)
      if(index(mode,'mov1').eq.0) then
        accept=acc/denom
       else
        accept=acc/(denom*nelec)
      endif

      do 25 ifr=1,nforce
        do 25 istate=1,nstates
        eave=ecum(istate,ifr)/wcum(istate,ifr)
        if(iblk.eq.1) then
          eerr=0
         else
          eerr=err(ecum(istate,ifr),ecm2(istate,ifr),istate,ifr)
        endif
        ieerr=nint(100000*eerr)
        if(ifr.eq.1) then
          if(iblk.eq.1) then
            peerr=0
            tpberr=0
            tjferr=0
           else
            peerr=err(pecum(istate),pecm2(istate),istate,ifr)
            tpberr=err(tpbcum(istate),tpbcm2(istate),istate,ifr)
            tjferr=err(tjfcum(istate),tjfcm2(istate),istate,ifr)
          endif
          peave=pecum(istate)/wcum(istate,ifr)
          tpbave=tpbcum(istate)/wcum(istate,ifr)
          tjfave=tjfcum(istate)/wcum(istate,ifr)

          ipeerr=nint(100000* peerr)
          itpber=nint(100000*tpberr)
          itjfer=nint(100000*tjferr)

          if(istate.eq.1) then
            write(6,'(f10.5,4(f10.5,''('',i5,'')''),25x,f10.5,i10)')
     &      enow(1,1),eave,ieerr,peave,ipeerr,tpbave,itpber,tjfave,itjfer,accept,iblk*nstep

            call prop_prt(wcum(1,ifr),iblk,6)
            call optci_prt(wcum(1,ifr),iblk,6)
c           call optorb_prt(wcum(1,ifr),eave,6)
c different meaning of last argument: 0 acuest, 1 finwrt
            call pcm_prt(wcum(1,ifr),iblk)

           else
            write(6,'(f10.5,4(f10.5,''('',i5,'')''))')
     &      enow(istate,1),eave,ieerr,peave,ipeerr,tpbave,itpber,tjfave,itjfer
          endif


         else
          fave=(ecum(istate,1)/wcum(istate,1)-ecum(istate,ifr)/wcum(istate,ifr))/deltot(ifr)
          ferr=err(fcum(istate,ifr),fcm2(istate,ifr),istate,1)/abs(deltot(ifr))
          iferr=nint(1.0d9*ferr)
          write(6,'(f10.5,f10.5,''('',i5,'')'',51x,f14.9,''('',i9,'')'')
     &    ') enow(istate,ifr),eave,ieerr,fave,iferr
        endif
  25  continue

      return
      end
