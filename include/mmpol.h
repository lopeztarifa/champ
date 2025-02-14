      parameter (MCHMM=1)

      character*80 mmpolfile_sites, mmpolfile_chmm

      common /mmpol_cntrl/ immpol,ich_mmpol,isites_mmpol,icall_mm,immpolprt
      common /mmpol_unit/ mmpolfile_sites, mmpolfile_chmm
      common /mmpol_parms/ x_mmpol(3,MCHMM),rqq(MCHMM,MCHMM),chmm(MCHMM),
     &   nchmm
      common /mmpol_dipol/ alfa(MCHMM),dipo(3,MCHMM)
      common /mmpol_ahpol/ ah_pol(3*MCHMM,3*MCHMM), bh_pol(3*MCHMM)
      common /mmpol_field/ enk_pol(3,MCHMM),eqk_pol(3,MCHMM)
      common /mmpol_pot/ penu_dp,penu_q,peqq,peq_dp, u_dd, u_self,
     &  pepol_dp,pepol_q
      common /mmpol_fdc/ rcolm,a_cutoff,screen1(MCHMM,MCHMM),screen2(MCHMM,MCHMM)
      common /mmpol_averages/ dmmpol_sum,dmmpol_cum,dmmpol_cm2,
     & cmmpol_sum,cmmpol_cum,cmmpol_cm2,eek_sum(3,MCHMM),
     & eek1_cum(MCHMM),eek1_cm2(MCHMM),eek2_cum(MCHMM),eek2_cm2(MCHMM),
     & eek3_cum(MCHMM),eek3_cm2(MCHMM)
      common /mmpol_inds/inds_pol(MCHMM)
