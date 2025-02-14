      subroutine sites(x,nelec,nsite)
c Written by Cyrus Umrigar
      implicit real*8(a-h,o-z)
      include 'vmc.h'

      parameter(half=0.5d0)

c routine to put electrons down around centers for an initial
c configuration if nothing else is available

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      dimension x(3,*),nsite(*)

c loop over spins and centers. If odd number of electrons on all
c atoms then the up-spins have an additional electron.

      l=0
      do 10 ispin=1,2
        do 10 i=1,ncent
          ju=(nsite(i)+2-ispin)/2
          do 10 j=1,ju
            l=l+1
            if (l.gt.nelec) return
            if(j.eq.1) then
              sitsca=1/znuc(iwctype(i))
             elseif(j.le.5) then
              sitsca=2/(znuc(iwctype(i))-2)
             else
              sitsca=3/(znuc(iwctype(i))-10)
            endif
            do 10 ic=1,3

c sample position from exponentials around center

             site=-dlog(rannyu(0))
             site=sign(site,(rannyu(0)-half))
   10        x(ic,l)=sitsca*site+cent(ic,i)
      write(6,'(''number of electrons placed ='',i5)') l
      if (l.lt.nelec) call fatal_error('SITES: bad input')
      return
      end
