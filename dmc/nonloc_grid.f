      subroutine nonloc_grid(iel,iw,x,psid,imove)

      implicit real*8 (a-h,o-z)

      include 'vmc.h'
      include 'dmc.h'
      include 'force.h'
      include 'optjas.h'
      include 'pseudo.h'

      common /wfsec/ iwftype(MFORCE),iwf,nwftype

      common /config/ xold(3,MELEC,MWALK,MFORCE),vold(3,MELEC,MWALK,MFORCE),
     &psido(MWALK,MFORCE),psijo(MWALK,MFORCE),peo(MWALK,MFORCE),d2o(MWALK,MFORCE)

      common /jaso/ fso(MELEC,MELEC),fijo(3,MELEC,MELEC)
     &,d2ijo(MELEC,MELEC),d2jo,fsumo,fjo(3,MELEC)

      common /distance/ rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT),rvec_ee(3,MMAT_DIM2),r_ee(MMAT_DIM2)

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

      common /contrldmc/ tau,rttau,taueff(MFORCE),tautot,nfprod,idmc,ipq
     &,itau_eff,iacc_rej,icross,icuspg,idiv_v,icut_br,icut_e

      common /casula/ t_vpsp(MCENT,MPS_QUAD,MELEC),icasula,i_vpsp
      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr

      common /contrl_per/ iperiodic,ibasis

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm

c here vpsp_det and dvpsp_det are dummy
      dimension vpsp_det(2),dvpsp_dj(MPARMJ)
      dimension x(*)

      iwf=iwftype(1)

      tauprim=tau
      if(icasula.gt.0)then
        call distances(iel,xold(1,1,iw,1))

        ioptjas_sav=ioptjas
        ioptorb_sav=ioptorb
        ioptci_sav=ioptci
        ioptjas=0
        ioptorb=0
        ioptci=0

        call nonloc_pot(xold(1,1,iw,1),rshift,rvec_en,r_en,pe,vpsp_det,dvpsp_dj,t_vpsp,iel,1)

        call multideterminant_tmove(psid,iel)

        ioptjas=ioptjas_sav
        ioptorb=ioptorb_sav
        ioptci=ioptci_sav

        i1=iel
        i2=iel
       else

        i1=1
        i2=nelec
      endif
      imove=0

c     do i=i1,i2
c     write(6,'(''t_vpsp before = '',100e10.2)') ((t_vpsp(ic,iq,i),ic=1,ncent),iq=1,nquad)
c     enddo

      t_norm=0.d0
      psidi=1.d0/psid
      do 10 ii=i1,i2
        i=ii
        if(i.gt.nelec) i=i-nelec
        if(i.lt.1) i=i+nelec
        do 10 iq=1,nquad
          do 10 ic=1,ncent
            t_vpsp(ic,iq,i)=t_vpsp(ic,iq,i)
            if(t_vpsp(ic,iq,i).gt.0.d0) t_vpsp(ic,iq,i)=0.d0
 10         t_norm=t_norm-t_vpsp(ic,iq,i)
      t_norm=1.d0+t_norm*tauprim
      t_normi=1.d0/t_norm
c     write(6,*) 'tnormi=',t_normi
c     do i=i1,i2
c     write(6,'(''t_vpsp after = '',100f14.6)') ((-tauprim*t_vpsp(ic,iq,i)*t_normi,ic=1,ncent),iq=1,nquad)
c     enddo

      if(t_norm.eq.1.d0) return

      t_cum=0.d0
      p=rannyu(0)
      do 20 ii=i1,i2
        i=ii
        if(i.gt.nelec) i=i-nelec
        if(i.lt.1) i=i+nelec
        do 20 iq=1,nquad
          do 20 ic=1,ncent
            t_cum=t_cum-tauprim*t_vpsp(ic,iq,i)*t_normi
            if(t_cum.gt.p)then
              ic_good=ic
              iq_good=iq
              iel_good=i
              imove=1
              go to 30
            endif
 20   continue

 30   if(imove.eq.1)then
        iq=iq_good
        ic=ic_good
        iel=iel_good
        if(icasula.lt.0) call distances(iel,xold(1,1,iw,1))
        ri=one/r_en(iel,ic)
        costh=rvec_en(1,iel,ic)*xq(iq)
     &       +rvec_en(2,iel,ic)*yq(iq)
     &       +rvec_en(3,iel,ic)*zq(iq)
        costh=costh*ri

        if(iperiodic.eq.0) then
          x(1)=r_en(iel,ic)*xq(iq)+cent(1,ic)
          x(2)=r_en(iel,ic)*yq(iq)+cent(2,ic)
          x(3)=r_en(iel,ic)*zq(iq)+cent(3,ic)
         else
          x(1)=r_en(iel,ic)*xq(iq)+cent(1,ic)+rshift(1,iel,ic)
          x(2)=r_en(iel,ic)*yq(iq)+cent(2,ic)+rshift(2,iel,ic)
          x(3)=r_en(iel,ic)*zq(iq)+cent(3,ic)+rshift(3,iel,ic)
        endif
c       write(6,*) 'moved B',iw,iel,(xold(kk,iel,iw,1),kk=1,3)
c       write(6,*) 'moved A',iw,iel,(x(kk),kk=1,3)
      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine t_vpsp_sav

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'dmc.h'
      include 'pseudo.h'
      include 'force.h'
      include 'basis.h'

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      common /casula/ t_vpsp(MCENT,MPS_QUAD,MELEC),icasula,i_vpsp
      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

      dimension t_vpsp_save(MCENT,MPS_QUAD,MELEC)

      save t_vpsp_save

      do 10 i=1,nelec
        do 10 iq=1,nquad
          do 10 ic=1,ncent
   10       t_vpsp_save(ic,iq,i)=t_vpsp(ic,iq,i)

      return

      entry t_vpsp_get

      do 20 i=1,nelec
        do 20 iq=1,nquad
          do 20 ic=1,ncent
   20       t_vpsp(ic,iq,i)=t_vpsp_save(ic,iq,i)

      return
      end
