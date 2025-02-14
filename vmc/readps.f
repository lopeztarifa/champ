      subroutine readps
c Written by Claudia Filippi

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'pseudo.h'
      include 'force.h'

      character*20 filename,atomtyp

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent

      common /pseudo_fahy/ potl(MPS_GRID,MCTYPE),ptnlc(MPS_GRID,MCTYPE,MPS_L)
     &,dradl(MCTYPE),drad(MCTYPE),rcmax(MCTYPE),npotl(MCTYPE)
     &,nlrad(MCTYPE)
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc

      common /qua/ xq0(MPS_QUAD),yq0(MPS_QUAD),zq0(MPS_QUAD)
     &,xq(MPS_QUAD),yq(MPS_QUAD),zq(MPS_QUAD),wq(MPS_QUAD),nquad

c nquad = number of quadrature points
c nlang = number of non-local potentials
c rcmax = cutoff radius for non-local potential
c npotl = number of mesh point for local potential
c dradl = spacing of uniform mesh for local potential

      do 20 ic=1,nctype

      if(ic.lt.10) then
        write(atomtyp,'(i1)') ic
       elseif(ic.lt.100) then
        write(atomtyp,'(i2)') ic
       else
        call fatal_error('READPS: problem atomtyp')
      endif

      filename='ps.data.'//atomtyp(1:index(atomtyp,' ')-1)
      open(3,file=filename,status='old',form='formatted')

      read(3,*) nquad
      write(6,'(''quadrature points'',i4)') nquad

      read(3,*) nlang,rcmax(ic)
      lpot(ic)=nlang+1

c local potential
      read(3,*)
      read(3,*) npotl(ic),nzion,dradl(ic)
      if(npotl(ic).gt.MPS_GRID) call fatal_error('READPS: npotl gt MPS_GRID')
      if(nzion.ne.int(znuc(iwctype(ic)))) call fatal_error('READPS: nzion ne znuc')

      read(3,*) (potl(i,ic),i=1,npotl(ic))

      do 5 i=1,npotl(ic)
  5     write(33,*) (i-1)*dradl(ic),potl(i,ic)

c non-local potential
      read(3,*)
      read(3,*) nlrad(ic),drad(ic)
      if(nlrad(ic).gt.MPS_GRID) call fatal_error('READPS: nrad gt MPS_GRID')

      if(drad(ic)*(nlrad(ic)-1).le.rcmax(ic)) then
        write(6,'(''non-local table max radius = '',
     &  f10.5,'' too small for cut-off = '',f10.5)')
     &  drad(ic)*(nlrad(ic)-1),rcmax(ic)
        call fatal_error('READPS')
      endif

      do 10 l=1,nlang
        read(3,*)
        read(3,*) (ptnlc(i,ic,l),i=1,nlrad(ic))
      do 10 i=1,nlrad(ic)
 10     write(34,*) (i-1)*drad(ic),ptnlc(i,ic,l)

      close(3)
 20   continue


      call gesqua (nquad,xq0,yq0,zq0,wq)
c     call gesqua (nquad,xq,yq,zq,wq)

      write(6,'(''quadrature points'')')
      do 30 i=1,nquad
 30     write(6,'(''xyz,w'',4f10.5)') xq0(i),yq0(i),zq0(i),wq(i)

      return
      end

c-----------------------------------------------------------------------
      subroutine getvps(rad,iel)
c Written by Claudia Filippi

      implicit real*8(a-h,o-z)
      include 'vmc.h'
      include 'force.h'

      common /atom/ znuc(MCTYPE),cent(3,MCENT),pecent
     &,iwctype(MCENT),nctype,ncent
      include 'pseudo.h'

      common /pseudo_fahy/ potl(MPS_GRID,MCTYPE),ptnlc(MPS_GRID,MCTYPE,MPS_L)
     &,dradl(MCTYPE),drad(MCTYPE),rcmax(MCTYPE),npotl(MCTYPE)
     &,nlrad(MCTYPE)
      common /pseudo/ vps(MELEC,MCENT,MPS_L),vpso(MELEC,MCENT,MPS_L,MFORCE)
     &,lpot(MCTYPE),nloc

      dimension rad(MELEC,MCENT)

      do 10 ic=1,ncent
        ict=iwctype(ic)
        r=rad(iel,ic)
c local potential
        if(r.lt.(npotl(ict)-1)*dradl(ict)) then
          ri=r/dradl(ict)
          ir=int(ri)
          ri=ri-dfloat(ir)
          ir=ir+1
          vps(iel,ic,lpot(ict))=potl(ir+1,ict)*ri+(1.d0-ri)*potl(ir,ict)
         else
          vps(iel,ic,lpot(ict))=-znuc(ict)/r
        endif
c non-local pseudopotential
        do 10 l=1,lpot(ict)-1
          if(r.lt.rcmax(ict)) then
            ri=r/drad(ict)
            ir=int(ri)
            ri=ri-dfloat(ir)
            ir=ir+1
            vps(iel,ic,l)=ptnlc(ir+1,ict,l)*ri+(1.d0-ri)*ptnlc(ir,ict,l)
           else
            vps(iel,ic,l)=0.0d0
          endif
   10 continue

      return
      end
