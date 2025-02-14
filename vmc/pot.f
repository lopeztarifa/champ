      subroutine pot_nn(cent,znuc,iwctype,ncent,pecent)
c Written by Cyrus Umrigar
c get nuclear potential energy
      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'pseudo.h'

      common /contrl_per/ iperiodic,ibasis
      dimension znuc(MCTYPE),cent(3,MCENT),iwctype(MCENT)

      common /da_pseudo/ da_pecent(3,MCENT),da_vps(3,MELEC,MCENT,MPS_L),
     & da_nonloc(3,MCENT)

      common /force_analy/ iforce_analy

      if(iperiodic.eq.0) then
        pecent=0
        do 20 i=2,ncent
          j1=i-1
          do 20 j=1,j1
            r2=0
            do 10 k=1,3
   10         r2=r2+(cent(k,i)-cent(k,j))**2
            r=dsqrt(r2)
   20       pecent=pecent+znuc(iwctype(i))*znuc(iwctype(j))/r
       else
        call pot_nn_ewald
      endif

      if(iforce_analy.eq.0) return

      if(iperiodic.eq.0) then
        do 25 i=1,ncent
          do 25 k=1,3
   25       da_pecent(k,i)=0.d0
        do 40 i=2,ncent
          j1=i-1
          do 40 j=1,j1
            zij=znuc(iwctype(i))*znuc(iwctype(j))
            r2=0
            do 30 k=1,3
   30         r2=r2+(cent(k,i)-cent(k,j))**2
            r=dsqrt(r2)
            ri=1/r
            ri2=ri*ri 
            do 40 k=1,3
              term=zij*(cent(k,i)-cent(k,j))*ri*ri2
              da_pecent(k,i)=da_pecent(k,i)-term
   40         da_pecent(k,j)=da_pecent(k,j)+term
      endif

      return
      end
