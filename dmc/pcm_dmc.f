      subroutine pcm_prt(iblk,wgcum,wgcm2)
      implicit real*8(a-h,o-z)
 
      include 'dmc.h'
      include 'force.h'
      include 'pcm.h'
      data hatokc/627.509541d0/

      dimension wgcum(MFORCE),wgcm2(MFORCE)

      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar

      rn_eff(w,w2)=w**2/w2
      error(x,x2,w,w2)=dsqrt(max((x2/w-(x/w)**2)/(rn_eff(w,w2)-1),0.d0))
      errg(x,x2,i)=error(x,x2,wgcum(i),wgcm2(i))

      if(ipcm.eq.0.or.ipcmprt.eq.0) return

      spcmave=spcmcum/wgcum(1)
      vpcmave=vpcmcum/wgcum(1)
      qopcm_ave=qopcm_cum/wgcum(1)

      if(iblk.eq.1) then
        spcmerr=0
        vpcmerr=0
        qopcm_err=0
       else
        spcmerr=errg(spcmcum,spcmcm2,1)
        vpcmerr=errg(vpcmcum,vpcmcm2,1)
        qopcm_err=errg(qopcm_cum,qopcm_cm2,1)

        ispcmerr=nint(100000*spcmerr)
        ivpcmerr=nint(100000*vpcmerr)
        iqopcm_err=nint(100000*qopcm_err)
      endif

      evalg_eff=nconf*nstep*rn_eff(wgcum(1),wgcm2(1))
      rtevalg_eff1=dsqrt(evalg_eff-1)

      spcmkcal=spcmave*hatokc
      vpcmkcal=vpcmave*hatokc
      sepcmkcal=spcmerr*hatokc
      vepcmkcal=vpcmerr*hatokc
      write(6,'(''pcm dG(surf) ='',t17,f12.7,'' +-'',f11.7,f9.5,2x,f12.7,'' +-'',f11.7)') 
     & spcmave,spcmerr,spcmerr*rtevalg_eff1,spcmkcal,sepcmkcal
      write(6,'(''pcm dG(vol)  ='',t17,f12.7,'' +-'',f11.7,f9.5,2x,f12.7,''+-'',f11.7)') 
     & vpcmave,vpcmerr,vpcmerr*rtevalg_eff1,vpcmkcal,vepcmkcal
c     write(6,'(''pcm qout     ='',t17,f12.7,'' +-'',f11.7,f9.5)') 
c    & qopcm_ave,qopcm_err,qopcm_err*rtevalg_eff1

c     gpcmkcal=spcmkcal+vpcmkcal

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_fin(iblk,wgcum,wgcm2)

      implicit real*8(a-h,o-z)

      include 'dmc.h'
      include 'force.h'
      include 'pcm.h'

      dimension wgcum(MFORCE),wgcm2(MFORCE)

      common /contrl/ nstep,nblk,nblkeq,nconf,nconf_new,isite,idump,irstar

      if(ipcm.eq.0) return
    
      ipcmprt_sav=ipcmprt
      ipcmprt=1
      call pcm_prt(iblk,wgcum(1),wgcm2(1))
      ipcmprt=ipcmprt_sav

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_save(iw)
      implicit real*8(a-h,o-z)
 
      include 'dmc.h'
      include 'pcm.h'
      common /pcm_hpsi/ pcms,pcmv,qopcm,enfpcm(MCHS)
      common /pcmo/ spcmo(MWALK),vpcmo(MWALK),qopcmo(MWALK),enfpcmo(MWALK,MCHS)

      if(ipcm.eq.0) return

      spcmo(iw)=pcms
      vpcmo(iw)=pcmv
      qopcmo(iw)=qopcm

c     write(6,*) 'CIAO',qopcm,qopcmo(iw),iw,spcmo(iw),vpcmo(iw)
      do i=1,nchs
      enfpcmo(iw,i)=enfpcm(i)
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_sum(p,q,iw)
      implicit real*8(a-h,o-z)
 
      include 'dmc.h'
      include 'pcm.h'
      common /pcm_hpsi/ pcms,pcmv,qopcm,enfpcm(MCHS)
      common /pcmo/ spcmo(MWALK),vpcmo(MWALK),qopcmo(MWALK),enfpcmo(MWALK,MCHS)

      if(ipcm.eq.0) return

      spcmsum=spcmsum+p*pcms+q*spcmo(iw)
      vpcmsum=vpcmsum+p*pcmv+q*vpcmo(iw)
      qopcm_sum=qopcm_sum+p*qopcm+q*qopcmo(iw)

c     write(6,*) 'HELLO',qopcm,qopcmo(iw),iw

      do i=1,nchs
      enfpcm_sum(i)= enfpcm_sum(i)+p*enfpcm(i)+q*enfpcmo(iw,i)
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_cum(wsum)
      implicit real*8(a-h,o-z)
 
      include 'dmc.h'
      include 'pcm.h'

      if(ipcm.eq.0) return

      spcmnow=spcmsum/wsum
      vpcmnow=vpcmsum/wsum
      qopcm_now=qopcm_sum/wsum

      spcmcm2=spcmcm2+spcmsum*spcmnow
      vpcmcm2=vpcmcm2+vpcmsum*vpcmnow
      qopcm_cm2=qopcm_cm2+qopcm_sum*qopcm_now

      spcmcum=spcmcum+spcmsum
      vpcmcum=vpcmcum+vpcmsum
      qopcm_cum=qopcm_cum+qopcm_sum
c     write (6,*) 'HELLO-CIAO', qopcm_cum

      do i=1,nchs
      enfpcm_now=enfpcm_sum(i)/wsum
      enfpcm_cm2(i)=enfpcm_cm2(i)+enfpcm_sum(i)*enfpcm_now
      enfpcm_cum(i)=enfpcm_cum(i)+enfpcm_sum(i)
      enddo

      return
      end
c-----------------------------------------------------------------------
      subroutine pcm_splitj(iw,iw2)
      implicit real*8(a-h,o-z)

      include 'dmc.h'
      include 'pcm.h'
      common /pcmo/ spcmo(MWALK),vpcmo(MWALK),qopcmo(MWALK),enfpcmo(MWALK,MCHS)


      spcmo(iw2)=spcmo(iw)
      vpcmo(iw2)=vpcmo(iw)
      qopcmo(iw2)=qopcmo(iw)

      do i=1,nchs
      enfpcmo(iw2,i)=enfpcmo(iw,i)
      enddo

      return
      end
