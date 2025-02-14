      subroutine nonloc(x,rshift,rvec_en,r_en,vpsp_det,dvpsp_dj,t_vpsp,i_vpsp)
c Written by Claudia Filippi, modified by Cyrus Umrigar and A. Scemama
      implicit real*8(a-h,o-z)
      parameter (one=1.d0)

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'pseudo.h'
      include 'ewald.h'
      include 'optjas.h'
      include 'optorb.h'
      include 'optorb_cblk.h'

      character*12 mode

      common /contr3/ mode

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl_per/ iperiodic,ibasis

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc
      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

      common /coefs/ coef(MBASIS,MORB,MWF),nbasis,norb
      common /dets/ cdet(MDET,MSTATES,MWF),ndet
      common /elec/ nup,ndn

      common /slater/ slmui(MMAT_DIM),slmdi(MMAT_DIM)
     &,fpu(3,MMAT_DIM),fpd(3,MMAT_DIM)
     &,fppu(MMAT_DIM),fppd(MMAT_DIM)
     &,ddx(3,MELEC),d2dx2(MELEC)

      common /multislater/ detu(MDET),detd(MDET)

      common /jaso/ fso(MELEC,MELEC),fijo(3,MELEC,MELEC)
     &,d2ijo(MELEC,MELEC),d2o,fsumo,fjo(3,MELEC)

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      common /orbval/ orb(MELEC,MORB),dorb(3,MELEC,MORB),ddorb(MELEC,MORB),ndetorb,nadorb
      common /da_orbval/ da_orb(3,MELEC,MORB,MCENT),da_d2orb(3,MELEC,MORB,MCENT),da_dorb(3,3,MELEC,MORB,MCENT)

      common /Bloc/ b(MORB,MELEC),xmat(MELEC**2,2)
     & ,tildem(MELEC,MORB,2)
      common /Bloc_dj/ b_dj(MORB,MELEC,MPARMJ)
      common /b_tmove/ b_t(MORB,MPS_QUAD,MCENT,MELEC),iskip(MELEC,MCENT)
      common /da_pseudo/ da_pecent(3,MCENT),da_vps(3,MELEC,MCENT,MPS_L),
     & da_nonloc(3,MCENT)

      common /da_energy_now/ da_energy(3,MCENT),da_psi(3,MCENT)

      common /force_analy/ iforce_analy

      dimension x(3,*),rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT)
      dimension rr_en(MELEC,MCENT),rr_en2(MELEC,MCENT),rr_en_sav(MCENT),rr_en2_sav(MCENT)
     &,xsav(3),rshift_sav(3,MCENT),rvec_en_sav(3,MCENT),r_en_sav(MCENT)

      dimension vpsp_det(*),dvpsp_dj(*),t_vpsp(MCENT,MPS_QUAD,*)
      dimension dpsij_ratio(MPARMJ)

      dimension orbn(MORB),dorbn(3,MORB),da_orbn(3,MCENT,MORB),term_radial_da_vps(3)
      dimension vjn(3),da_ratio_jn(3,MCENT),dd1(MELEC,MCENT),dd1_sav(MCENT)

      do 11 ic=1,ncent
cJF this is the culprit
        if(iforce_analy.eq.0) then
          do 2 i=1,nelec
            call scale_dist(r_en(i,ic),rr_en(i,ic),1)
   2        call scale_dist(r_en(i,ic),rr_en2(i,ic),2)
         else
          do 3 i=1,nelec
            call scale_dist1(r_en(i,ic),rr_en(i,ic),dd1(i,ic),1)
cJF added to see what happens --> gives same as iforce_analy = 0
c           call scale_dist(r_en(i,ic),rr_en2(i,ic),2)
   3        if(ioptjas.gt.0) call scale_dist(r_en(i,ic),rr_en2(i,ic),2)
        endif
   11 continue

      vpsp_det(1)=0
      vpsp_det(2)=0
        do 12 iparm=1,nparmj
   12     dvpsp_dj(iparm)=0

      if(i_vpsp.gt.0)then
        i1=i_vpsp
        i2=i_vpsp
       else
        i1=1
        i2=nelec
      endif

      do 100 i=i1,i2

        iab=1
        if(i.gt.nup) iab=2

        do 100 ic=1,ncent
          ict=iwctype(ic)

c vps was calculated by calling getvps_tm from nonloc_pot
          iskip(i,ic)=1
          do 15 l=1,lpot(ict)-1
   15       if(dabs(vps(i,ic,l)).gt.1.d-4) iskip(i,ic)=0

c skip if non-local components are zero
          if(iskip(i,ic).eq.0) then

            ri=one/r_en(i,ic)

            do 20 k=1,3
   20         xsav(k)=x(k,i)
            do 30 jc=1,ncent
              r_en_sav(jc)=r_en(i,jc)
              rr_en_sav(jc)=rr_en(i,jc)
              rr_en2_sav(jc)=rr_en2(i,jc)
              dd1_sav(jc)=dd1(i,jc)
              do 30 k=1,3
                rshift_sav(k,jc)=rshift(k,i,jc)
   30           rvec_en_sav(k,jc)=rvec_en(k,i,jc)

c loop quadrature points
            do 60 iq=1,nquad

              costh=rvec_en_sav(1,ic)*xq(iq)
     &             +rvec_en_sav(2,ic)*yq(iq)
     &             +rvec_en_sav(3,ic)*zq(iq)
              costh=costh*ri

              call dist_quad(i,ic,iq,x(1,i),r_en,rvec_en,rshift,rr_en,rr_en2,dd1)

              iel=i
              call orbitals_quad(iel,x,rvec_en,r_en,orbn,dorbn,da_orbn,iforce_analy)

              call nonlocd(iel,orbn,detu,detd,slmui,slmdi,det_ratio)
              if(ioptjas.gt.0) then
                call deriv_nonlocj(iel,x,rshift,rvec_en,r_en,rr_en,rr_en2,dd1,psij_ratio,dpsij_ratio,vjn,da_ratio_jn)
               else
                call nonlocj(iel,x,rshift,rvec_en,r_en,rr_en,rr_en2,dd1,fso,psij_ratio,vjn,da_ratio_jn)
              endif

c             write(6,*) 'PSI',psij_ratio
c             write(6,*) 'HELLO',(vjn(k),k=1,3)
c             do ll=1,ncent
c               write(6,*) 'HELLO',(da_ratio_jn(k,ll),k=1,3)
c             enddo

              term_radial=0.d0
              do 50 l=1,lpot(ict)-1
   50           term_radial=term_radial+yl0(l,costh)*vps(i,ic,l)
              term_radial=term_radial*wq(iq)*exp(psij_ratio)
        
c vpsp_det  = vnl(D_kref J)/(D_kref J)
              vpsp_det(iab)=vpsp_det(iab)+det_ratio*term_radial

c pseudopotential contribution to B_eloc matrix
               do 51 iorb=1,norb+nadorb
   51            b(iorb,i)=b(iorb,i)+orbn(iorb)*term_radial

c dvpsp_dj  = vnl(D_kref dJ)/(D_kref J)
              if(ioptjas.gt.0) then
                term=term_radial*det_ratio
                do 55 iparm=1,nparmj
                  dvpsp_dj(iparm)=dvpsp_dj(iparm)+term*dpsij_ratio(iparm)

                  do 55 iorb=1,norb
   55               b_dj(iorb,i,iparm)=b_dj(iorb,i,iparm)+orbn(iorb)*term_radial*dpsij_ratio(iparm)
              endif

c transition probabilities for Casula's moves in DMC
              if(index(mode,'dmc').ne.0) then
                t_vpsp(ic,iq,i)=det_ratio*term_radial 
                do 56 iorb=1,norb
   56             b_t(iorb,iq,ic,i)=orbn(iorb)*term_radial
              endif

              if(iforce_analy.gt.0) 
     &        call compute_da_bnl(iel,ic,ict,iq,r_en_sav,rvec_en_sav,costh,
     &                                     term_radial,orbn,dorbn,da_orbn,psij_ratio,vjn,da_ratio_jn)
               
c end loop quadrature points
   60       continue

            do 68 k=1,3
   68         x(k,i)=xsav(k)
            do 70 jc=1,ncent
              r_en(i,jc)=r_en_sav(jc)
              rr_en(i,jc)=rr_en_sav(jc)
              rr_en2(i,jc)=rr_en2_sav(jc)
              dd1(i,jc)=dd1_sav(jc)
              do 70 k=1,3
                rshift(k,i,jc)=rshift_sav(k,jc)
   70           rvec_en(k,i,jc)=rvec_en_sav(k,jc)
              
c elseif iskip
           elseif(i_vpsp.ne.0)then
            do 80 iq=1,nquad
              t_vpsp(ic,iq,i)=0.d0
              do 80 iorb=1,norb
   80           b_t(iorb,iq,ic,i)=0.d0
c endif iskip
          endif
c end loop nelec, ncent
  100 continue

      if(ipr.ge.4) write(6,'(''vpsp_det,detu(1),detd(1),r_en(1)='',100d12.4)')
     &,(vpsp_det(iab),iab=1,2),detu(1),detd(1),r_en(1,1)

      return
      end
c-----------------------------------------------------------------------
      function yl0(l,costh)

      implicit real*8(a-h,o-z)

      if(l.eq.1) then
        yl0=1.d0
       elseif(l.eq.2) then
        yl0=3.d0*costh
       elseif(l.eq.3) then
        yl0=2.5d0*(3*costh*costh-1)
       else
        call fatal_error('YL0: implemented to l=3 only')
      endif

      return
      end

c-----------------------------------------------------------------------

      function dyl0(l,costh)
      implicit real*8(a-h,o-z)

      if(l.eq.1) then
        dyl0=0.d0
       elseif(l.eq.2) then
        dyl0=3.d0
       elseif(l.eq.3) then
        dyl0=15.d0*costh
       else
        call fatal_error('YL0: implemented to l=3 only')
      endif

      return
      end

c-----------------------------------------------------------------------
      subroutine dist_quad(i,ic,iq,x,r_en,rvec_en,rshift,rr_en,rr_en2,dd1)

      implicit real*8(a-h,o-z)
      parameter (one=1.d0)

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'pseudo.h'
      include 'ewald.h'

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl_per/ iperiodic,ibasis

      common /elec/ nup,ndn
      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

      common /force_analy/ iforce_analy

      dimension x(3),rshift(3,MELEC,MCENT),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT)
      dimension rr_en(MELEC,MCENT),rr_en2(MELEC,MCENT),dd1(MELEC,MCENT)

      if(iperiodic.eq.0) then
        x(1)=r_en(i,ic)*xq(iq)+cent(1,ic)
        x(2)=r_en(i,ic)*yq(iq)+cent(2,ic)
        x(3)=r_en(i,ic)*zq(iq)+cent(3,ic)
       else
        x(1)=r_en(i,ic)*xq(iq)+cent(1,ic)+rshift(1,i,ic)
        x(2)=r_en(i,ic)*yq(iq)+cent(2,ic)+rshift(2,i,ic)
        x(3)=r_en(i,ic)*zq(iq)+cent(3,ic)+rshift(3,i,ic)
      endif

      do 40 jc=1,ncent
        do 35 k=1,3
   35     rvec_en(k,i,jc)=x(k)-cent(k,jc)

        if(jc.ne.ic) then
          if(iperiodic.eq.0) then
            r_en(i,jc)=0
            do 39 k=1,3
   39         r_en(i,jc)=r_en(i,jc)+rvec_en(k,i,jc)**2
            r_en(i,jc)=dsqrt(r_en(i,jc))
           else
            call find_image4(rshift(1,i,jc),rvec_en(1,i,jc),r_en(i,jc))
          endif

          if(iforce_analy.eq.0) then
            call scale_dist(r_en(i,jc),rr_en(i,jc),1)
            call scale_dist(r_en(i,jc),rr_en2(i,jc),2)
           else
            call scale_dist1(r_en(i,jc),rr_en(i,jc),dd1(i,jc),1)
            call scale_dist(r_en(i,jc),rr_en2(i,jc),2)
          endif
        endif

   40 continue

      return
      end
c-----------------------------------------------------------------------
      subroutine orbitals_quad(iel,x,rvec_en,r_en,orbn,dorbn,da_orbn,iforce_analy)
c Written by Claudia Filippi, modified by Cyrus Umrigar and A. Scemama

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include '3dgrid_flags.h'

      common /contrl_per/ iperiodic,ibasis
      common /wfsec/ iwftype(MFORCE),iwf,nwftype
      common /elec/ nup,ndn

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      common /phifun/ phin(MBASIS,MELEC),dphin(3,MBASIS,MELEC)
     &,d2phin(MBASIS,MELEC),d2phin_all(3,3,MBASIS,MELEC),d3phin(3,MBASIS,MELEC)
     &,n0_nbasis(MELEC),n0_ibasis(MBASIS,MELEC),n0_ic(MBASIS,MELEC)

      common /coefs/ coef(MBASIS,MORB,MWF),nbasis,norb

      common /orbval/ orb(MELEC,MORB),dorb(3,MELEC,MORB),ddorb(MELEC,MORB),ndetorb,nadorb

      common /numbas1/ nbastyp(MCTYPE), iwlbas(MBASIS,MCTYPE)

      dimension x(3),rvec_en(3,MELEC,MCENT),r_en(MELEC,MCENT)
      dimension orbn(*),dorbn(3,*),da_orbn(3,MCENT,*),dtmp(3)

      if(iperiodic.eq.0) then

c get the value from the 3d-interpolated orbitals
        ier=0
        if(i3dsplorb.ge.1) then
          do 10 iorb=1,norb+nadorb
            ddorb=0     ! Don't compute the laplacian
            dtmp(1)=0   ! Don't compute the gradients
            dtmp(2)=0   ! Don't compute the gradients
            dtmp(3)=0   ! Don't compute the gradients
   10       call spline_mo(x,iorb,orbn(iorb),dtmp,ddorb,ier)
         elseif(i3dlagorb.ge.1) then
          call lagrange_mose(1,x,orbn,ier)
         else
          ier=1
        endif 

        if(ier.eq.1) then
c get basis functions for electron iel
          call basis_fnse_v(iel,rvec_en,r_en)

          do 25 iorb=1,norb+nadorb
            orbn(iorb)=0.d0
c           do 25 m=1,nbasis
            do 25 m0=1,n0_nbasis(iel)
              m=n0_ibasis(m0,iel)
   25         orbn(iorb)=orbn(iorb)+coef(m,iorb,iwf)*phin(m,iel)

          if(iforce_analy.gt.0) then

            do 70 iorb=1,norb
              do 30 ic=1,ncent
                do 30 k=1,3
   30             da_orbn(k,ic,iorb)=0.d0
              do 50 m0=1,n0_nbasis(iel)
                m=n0_ibasis(m0,iel)
                ic=n0_ic(m0,iel)
                ii=iwctype(ic)
                do 50 k=1,3
   50             da_orbn(k,ic,iorb)=da_orbn(k,ic,iorb)-coef(m,iorb,iwf)*dphin(k,m,iel)
              do 60 k=1,3
   60           dorbn(k,iorb)=0.d0
              do 70 ic=1,ncent
                do 70 k=1,3
   70              dorbn(k,iorb)=dorbn(k,iorb)-da_orbn(k,ic,iorb)
          endif
c         write(6,*)'orb_quad iel,ren',iel,rvec_en(1,iel,1),rvec_en(1,iel,2)
c         write(6,*)'orb_quad da_orb', da_orbn(1,1,1),dphin(1,1,iel)
        endif

       else

        call orbitals_pwe(iel,x,orbn)

      endif

      return
      end

c-----------------------------------------------------------------------
      subroutine nonlocd(iel,orb,detu,detd,slmui,slmdi,ratio)
c Written by Claudia Filippi, modified by Cyrus Umrigar and A. Scemama

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include '3dgrid_flags.h'

      common /multidet/ kref,numrep_det(MDET,2),irepcol_det(MELEC,MDET,2),ireporb_det(MELEC,MDET,2)
     & ,iwundet(MDET,2),iactv(2),ivirt(2)

      common /dets/ cdet(MDET,MSTATES,MWF),ndet
      common /elec/ nup,ndn
      common /dorb/ iworbd(MELEC,MDET)

      dimension x(3)
      dimension detu(*),detd(*),slmui(MMAT_DIM),slmdi(MMAT_DIM)
      dimension orb(*),dorb(3)

      if(iel.le.nup) then

        ikel=nup*(iel-1)

        ratio=0.d0
        do 30 j=1,nup
   30     ratio=ratio+slmui(j+ikel)*orb(iworbd(j,kref))

       else

        ikel=ndn*(iel-nup-1)

        ratio=0.d0
        do 55 j=1,ndn
   55     ratio=ratio+slmdi(j+ikel)*orb(iworbd(j+nup,kref))

      endif

      return
      end
c-----------------------------------------------------------------------
      subroutine nonlocj(iel,x,rshift,rvec_en,r_en,rr_en,rr_en2,dd1,fso,ratio_jn,vjn,da_ratio_jn)
c Written by Claudia Filippi, modified by Cyrus Umrigar

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'ewald.h'
      include 'force.h'
      include 'mstates.h'

      parameter (half=.5d0)

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /contrl_per/ iperiodic,ibasis
      common /contr2/ ijas,icusp,icusp2,isc,ianalyt_lap
     &,ifock,i3body,irewgt,iaver,istrch
      common /dets/ cdet(MDET,MSTATES,MWF),ndet
      common /elec/ nup,ndn

      common /jaspar/ nspin1,nspin2,sspin,sspinn,is

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      common /bparm/ nspin2b,nocuspb

      common /da_jastrow4val/ da_j(3,MELEC,MCENT),da_d2j(3,MELEC,MCENT),da_vj(3,3,MELEC,MCENT)

      common /force_analy/ iforce_analy

      dimension fso(MELEC,*)
      dimension x(3,*),rshift(3,MELEC,MCENT),rvec_en(3,MELEC,*)
      dimension r_en(MELEC,MCENT),rr_en(MELEC,MCENT),rr_en2(MELEC,MCENT)
     &,fsn(MELEC,MELEC),dx(3),dd1(MELEC,MCENT),vjn(3),da_ratio_jn(3,MCENT)

      fsumn=0

       do 1 k=1,3
   1     vjn(k)=0.d0

      if (nelec.lt.2) goto 47

      do 45 jj=1,nelec

        if(jj.eq.iel) goto 45
        if(jj.lt.iel) then
          i=iel
          j=jj
         else
          i=jj
          j=iel
        endif

        sspinn=1
        ipar=0
        isb=1
        if(i.le.nup .or. j.gt.nup) then
          if(nspin2b.eq.2) then
            isb=2
           elseif(nocuspb.eq.0) then
            sspinn=half
          endif
          ipar=1
        endif

        do 10 k=1,3
   10     dx(k)=x(k,jj)-x(k,iel)

        if(iperiodic.eq.0) then
          rij=0
          do 20 k=1,3
   20       rij=rij+dx(k)**2
          rij=dsqrt(rij)
         else
          call find_image3(dx,rij)
        endif

c e-e terms
        if(iforce_analy.eq.0) then
          call scale_dist(rij,u,1)
         else
          call scale_dist1(rij,u,dd1u,1)
          dum=dpsibnl(u,isb,ipar)*dd1u/rij
          do 30 k=1,3
            dumk=-dum*dx(k)
   30       vjn(k)=vjn(k)+dumk
        endif

        fsn(i,j)=psibnl(u,isb,ipar)

c e-e-n terms
c The scaling is switched in psinl, so do not do it here.
      if(isc.ge.12) call scale_dist(rij,u,3)

        do 40 ic=1,ncent
          it=iwctype(ic)
   40     fsn(i,j)=fsn(i,j) +
     &    psinl(u,rshift(1,i,ic),rshift(1,j,ic),rr_en2(i,ic),rr_en2(j,ic),it)
        fsumn=fsumn+fsn(i,j)-fso(i,j)
   45 continue

c e-n terms
   47 fsn(iel,iel)=0

      do 50 ic=1,ncent
        it=iwctype(ic)
   50   fsn(iel,iel)=fsn(iel,iel)+psianl(rr_en(iel,ic),it)

      fsumn=fsumn+fsn(iel,iel)-fso(iel,iel)
      ratio_jn=fsumn

      if(iforce_analy.eq.0) return

       do 70 ic=1,ncent
        it=iwctype(ic)
        dum=dpsianl(rr_en(iel,ic),it)*dd1(iel,ic)/r_en(iel,ic)
        do 70 k=1,3
          dumk=dum*rvec_en(k,iel,ic)
          vjn(k)=vjn(k)+dumk
   70     da_ratio_jn(k,ic)=-dumk-da_j(k,iel,ic)

      return
      end
c-----------------------------------------------------------------------
      subroutine compute_da_bnl(i,ic,ict,iq,r_en_sav,rvec_en_sav,costh,
     &                                   term_radial,orbn,dorbn,da_orbn,psij_ratio,vjn,da_ratio_jn)

      implicit real*8(a-h,o-z)
      parameter (one=1.d0)

      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'pseudo.h'

      common /const/ pi,hb,etrial,delta,deltai,fbias,nelec,imetro,ipr
      common /elec/ nup,ndn

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc
      common /da_pseudo/ da_pecent(3,MCENT),da_vps(3,MELEC,MCENT,MPS_L),
     & da_nonloc(3,MCENT)

      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

      common /coefs/ coef(MBASIS,MORB,MWF),nbasis,norb

      common /Bloc_da/ db(3,MELEC,MORB,MCENT)

      common /force_analy/ iforce_analy

      dimension rvec_en_sav(3,MCENT),r_en_sav(MCENT)

      dimension orbn(MORB),dorbn(3,MORB),vjn(3)
      dimension da_orbn(3,MCENT,MORB),da_ratio_jn(3,MCENT)

      dimension term_radial_da_vps(3)

      if(iforce_analy.eq.0) return

      iel=i
      sav_db=db(1,iel,1,ic)

      da_term_radial=0.d0
      do 51 k=1,3
   51   term_radial_da_vps(k)=0.d0

      do 52 l=1,lpot(ict)-1
        da_term_radial=da_term_radial+dyl0(l,costh)*vps(i,ic,l)
        do 52 k=1,3
   52     term_radial_da_vps(k)=term_radial_da_vps(k)+yl0(l,costh)*da_vps(k,i,ic,l)*wq(iq)*exp(psij_ratio)
      da_term_radial=da_term_radial*wq(iq)*exp(psij_ratio)

      r_en_savi=1.d0/r_en_sav(ic)
      r_en_savi2=r_en_savi*r_en_savi
      do 54 iorb=1,norb
        db(1,iel,iorb,ic)=db(1,iel,iorb,ic)+term_radial_da_vps(1)*orbn(iorb)
     &                   +da_term_radial*(-xq(iq)*r_en_savi+costh*rvec_en_sav(1,ic)*r_en_savi2)*orbn(iorb)
        db(2,iel,iorb,ic)=db(2,iel,iorb,ic)+term_radial_da_vps(2)*orbn(iorb)
     &                   +da_term_radial*(-yq(iq)*r_en_savi+costh*rvec_en_sav(2,ic)*r_en_savi2)*orbn(iorb)
        db(3,iel,iorb,ic)=db(3,iel,iorb,ic)+term_radial_da_vps(3)*orbn(iorb)
     &                   +da_term_radial*(-zq(iq)*r_en_savi+costh*rvec_en_sav(3,ic)*r_en_savi2)*orbn(iorb)

                
         db_tmp1=term_radial*(dorbn(1,iorb)+orbn(iorb)*vjn(1))
         db_tmp2=term_radial*(dorbn(2,iorb)+orbn(iorb)*vjn(2))
         db_tmp3=term_radial*(dorbn(3,iorb)+orbn(iorb)*vjn(3))

         dum=xq(iq)*db_tmp1+yq(iq)*db_tmp2+zq(iq)*db_tmp3

         db(1,iel,iorb,ic)=db(1,iel,iorb,ic)-dum*rvec_en_sav(1,ic)*r_en_savi+db_tmp1
         db(2,iel,iorb,ic)=db(2,iel,iorb,ic)-dum*rvec_en_sav(2,ic)*r_en_savi+db_tmp2
         db(3,iel,iorb,ic)=db(3,iel,iorb,ic)-dum*rvec_en_sav(3,ic)*r_en_savi+db_tmp3

         do 54 jc=1,ncent
c          if(jc.ne.ic) then
             do 53 k=1,3
   53          db(k,iel,iorb,jc)=db(k,iel,iorb,jc)+term_radial*(da_orbn(k,jc,iorb)+orbn(iorb)*da_ratio_jn(k,jc))
c          endif
   54 continue
               
c     write(6,*) 'AFT',iel,ic,iq,db(1,iel,1,ic)-sav_db
      return
      end
