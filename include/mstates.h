      parameter (MSTATES=3,MDETCSFX=20)

      common /mstates_ctrl/ iefficiency, iguiding, nstates_psig
      common /mstates2/ effcum(MSTATES),effcm2(MSTATES)
      common /mstates3/ weights_g(MSTATES),iweight_g(MSTATES)
