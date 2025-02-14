      subroutine optx_jas_orb_sum(wtg_new,wtg_old,iflag)

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optorb.h'
      include 'optorb_cblk.h'

      common /deloc_dj/ denergy(MPARMJ,MSTATES)
      common /derivjas/ gvalue(MPARMJ),g(3,MELEC,MPARMJ)
     &,d2g(MPARMJ),go(MELEC,MELEC,MPARMJ)

      common /gradhessjo/ gvalue_old(MPARMJ),denergy_old(MPARMJ,MSTATES)
     &,d1d2a_old(MCTYPE),d2d2a_old(MCTYPE),d1d2b_old(2),d2d2b_old(2)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /mix_jas_orb/ dj_o(MPARMJ,MXREDUCED,MSTATES),dj_oe(MPARMJ,MXREDUCED,MSTATES),
     &de_o(MPARMJ,MXREDUCED,MSTATES),dj_ho(MPARMJ,MXREDUCED,MSTATES)

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      dimension wtg_new(*),wtg_old(*)

      if(ioptjas.eq.0.or.ioptorb.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      do 200 istate=1,nstates

      p=wtg_new(istate)
      do 10 i=1,nparmj
        do 10 j=1,nreduced
        dj_o(i,j,istate)=dj_o(i,j,istate)  +p*gvalue(i)*orb_o(j,istate)
        dj_oe(i,j,istate)=dj_oe(i,j,istate)+p*gvalue(i)*orb_oe(j,istate)
        dj_ho(i,j,istate)=dj_ho(i,j,istate)+p*gvalue(i)*orb_ho(j,istate)
   10   de_o(i,j,istate)=de_o(i,j,istate)  +p*denergy(i,istate)*orb_o(j,istate)

  200 continue

      if(iflag.eq.0) return

      do 300 istate=1,nstates

      q=wtg_old(istate)
      do 20 i=1,nparmj
        do 20 j=1,nreduced
        dj_o(i,j,istate)=dj_o(i,j,istate)  +q*gvalue_old(i)*orb_o_old(j,istate)
        dj_oe(i,j,istate)=dj_oe(i,j,istate)+q*gvalue_old(i)*orb_oe_old(j,istate)
        dj_ho(i,j,istate)=dj_ho(i,j,istate)+q*gvalue_old(i)*orb_ho_old(j,istate)
   20   de_o(i,j,istate)=de_o(i,j,istate)  +q*denergy_old(i,istate)*orb_o_old(j,istate)

  300 continue

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_orb_init

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optorb.h'
      include 'optorb_cblk.h'

      common /mix_jas_orb/ dj_o(MPARMJ,MXREDUCED,MSTATES),dj_oe(MPARMJ,MXREDUCED,MSTATES),
     &de_o(MPARMJ,MXREDUCED,MSTATES),dj_ho(MPARMJ,MXREDUCED,MSTATES)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      if(ioptjas.eq.0.or.ioptorb.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      do 200 istate=1,nstates

      do 10 i=1,nparmj
        do 10 j=1,nreduced
          dj_o(i,j,istate)=0
          dj_oe(i,j,istate)=0
          dj_ho(i,j,istate)=0
  10      de_o(i,j,istate)=0

  200 continue

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_orb_dump(iu)

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optorb.h'
      include 'optorb_cblk.h'

      common /mix_jas_orb/ dj_o(MPARMJ,MXREDUCED,MSTATES),dj_oe(MPARMJ,MXREDUCED,MSTATES),
     &de_o(MPARMJ,MXREDUCED,MSTATES),dj_ho(MPARMJ,MXREDUCED,MSTATES)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      if(ioptjas.eq.0.or.ioptorb.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      do 200 istate=1,nstates
  200 write(iu) ((dj_o(i,j,istate),dj_oe(i,j,istate),dj_ho(i,j,istate),de_o(i,j,istate),i=1,nparmj),j=1,nreduced)
  

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_orb_rstrt(iu)

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optorb.h'

      common /mix_jas_orb/ dj_o(MPARMJ,MXREDUCED,MSTATES),dj_oe(MPARMJ,MXREDUCED,MSTATES),
     &de_o(MPARMJ,MXREDUCED,MSTATES),dj_ho(MPARMJ,MXREDUCED,MSTATES)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      if(ioptjas.eq.0.or.ioptorb.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      do 200 istate=1,nstates
  200 read(iu) ((dj_o(i,j,istate),dj_oe(i,j,istate),dj_ho(i,j,istate),de_o(i,j,istate),i=1,nparmj),j=1,nreduced)

      return
      end
c-----------------------------------------------------------------------
      subroutine optx_jas_orb_fin(wcum,ecum)
      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'
      include 'mstates.h'
      include 'optjas.h'
      include 'optci.h'
      include 'optorb.h'
      include 'optorb_cblk.h'

      common /gradhessj/ dj(MPARMJ,MSTATES),dj_e(MPARMJ,MSTATES),dj_de(MPARMJ,MPARMJ,MSTATES)
     &,dj_dj(MPARMJ,MPARMJ,MSTATES),dj_dj_e(MPARMJ,MPARMJ,MSTATES),de(MPARMJ,MSTATES)
     &,d2j(MPARMJ,MPARMJ,MSTATES),d2j_e(MPARMJ,MPARMJ,MSTATES),de_e(MPARMJ,MSTATES)
     &,e2(MPARMJ,MSTATES),dj_e2(MPARMJ,MSTATES),de_de(MPARMJ,MPARMJ,MSTATES)

      common /mix_jas_orb/ dj_o(MPARMJ,MXREDUCED,MSTATES),dj_oe(MPARMJ,MXREDUCED,MSTATES),
     &de_o(MPARMJ,MXREDUCED,MSTATES),dj_ho(MPARMJ,MXREDUCED,MSTATES)

      common /csfs/ ccsf(MDET,MSTATES,MWF),cxdet(MDET*MDETCSFX)
     &,icxdet(MDET*MDETCSFX),iadet(MDET),ibdet(MDET),ncsf,nstates

      common /gradhess_mix_jas_orb/  h_mix_jas_orb(2*MPARMJ,MXREDUCED),s_mix_jas_orb(MPARMJ,MXREDUCED)

      common /sa_weights/ weights(MSTATES),iweight(MSTATES),nweight

      common /optwf_contrl/ ioptjas,ioptorb,ioptci,nparm
      common /optwf_parms/ nparml,nparme,nparmd,nparms,nparmg,nparmj

      dimension wcum(*),ecum(*),grad_orb(MXREDUCED)

      if(ioptjas.eq.0.or.ioptorb.eq.0.or.method.eq.'sr_n'.or.method.eq.'lin_d') return

      call p2gtid('optwf:iuse_orbeigv',iuse_orbeigv,0,1)
      call p2gtid('optwf:approx_mix',iapprox,0,1)

      do 1 i=1,nparmj
        do 1 j=1,nreduced
          s_mix_jas_orb(i,j)=0
          h_mix_jas_orb(i,j)=0
   1      h_mix_jas_orb(i+nparmj,j)=0

c Hessian method
      if(method.eq.'hessian') then

c Exact mixed Hessian terms not implemented
      if(iuse_orbeigv.ne.0) then
        call fatal_error('OPTX_JAS_ORB_FIN: exact mix hessian formulas not implemented')
       else
c Approximate mixed Hessian terms using orbital eigenvalues
        do 50 istate=1,nstates

        wts=weights(istate)

        passes=wcum(istate)
        passesi=1/passes
        eave=ecum(istate)*passesi

        do 10 j=1,nreduced
 10       grad_orb(j)=2*(orb_oe_cum(j,istate)-eave*orb_o_cum(j,istate))*passesi
 
        do 20 i=1,nparmj
          grad_jas=2*(dj_e(i,istate)-eave*dj(i,istate))*passesi
          do 20 j=1,nreduced
            h1=2*(2*(dj_oe(i,j,istate)-eave*dj_o(i,j,istate))-dj(i,istate)*grad_orb(j)-grad_jas*orb_o_cum(j,istate))
            h2=2*(de_o(i,j,istate)-de(i,istate)*orb_o_cum(j,istate)*passesi)
 20         h_mix_jas_orb(i,j)=h_mix_jas_orb(i,j)+wts*(h1+h2)*passesi

 50   continue

      endif

c Linear method
      elseif(method.eq.'linear') then

c Exact Hamiltonian mixed terms on semi-orthogonal basis
      if(iuse_orbeigv.eq.0) then

      do 70 istate=1,nstates

      wts=weights(istate)

      passes=wcum(istate)
      passesi=1/passes
      eave=ecum(istate)*passesi

      do 60 i=1,nparmj
        do 60 j=1,nreduced
c Overlap jas_orb
          s_mix_jas_orb(i,j)=s_mix_jas_orb(i,j)+wts*(dj_o(i,j,istate)-dj(i,istate)*orb_o_cum(j,istate)*passesi)*passesi
c Hamiltonian jas_orb
          h_mix_jas_orb(i,j)=h_mix_jas_orb(i,j)+wts*(dj_ho(i,j,istate)+
     &    (eave*dj(i,istate)*orb_o_cum(j,istate)-dj(i,istate)*orb_ho_cum(j,istate)-
     &    orb_o_cum(j,istate)*dj_e(i,istate))*passesi)*passesi
c Hamiltonian orb_jas
          h_mix_jas_orb(i+nparmj,j)=h_mix_jas_orb(i+nparmj,j)+wts*(de_o(i,j,istate)+dj_oe(i,j,istate)+
     &    (eave*dj(i,istate)*orb_o_cum(j,istate)-dj(i,istate)*orb_oe_cum(j,istate)-
     &    orb_o_cum(j,istate)*(de(i,istate)+dj_e(i,istate)))*passesi)*passesi

 60   continue

 70   continue

      endif

      endif

      if(method.eq.'linear') then
      if(iapprox.eq.1) then
        do 100 i=1,nparmj
          do 100 j=1,nreduced
 100        h_mix_jas_orb(i,j)=h_mix_jas_orb(i+nparmj,j)
       elseif(iapprox.eq.2) then
        do 110 i=1,nparmj
          do 110 j=1,nreduced
            s_mix_jas_orb(i,j)=0
            h_mix_jas_orb(i,j)=0
 110        h_mix_jas_orb(i+nparmj,j)=0
       elseif(iapprox.eq.3) then
        do 120 i=1,nparmj
          do 120 j=1,nreduced
            h_mix_jas_orb(i,j)=0.5*(h_mix_jas_orb(i,j)+h_mix_jas_orb(i+nparmj,j))
 120        h_mix_jas_orb(i+nparmj,j)=h_mix_jas_orb(i,j)
      endif

      endif

      return
      end
