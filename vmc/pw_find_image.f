      subroutine check_lattice(rlatt,cutr,isim_cell)
c Written by Cyrus Umrigar
c Checks to see if the lattice vectors specified are the smallest
c ones possible.  This is necessary for the simple heuristic algorithm
c Mathew Foulkes suggested to find the image particle (if any) that lies in the
c inscribing sphere of the nearest Wigner Seitz cell.  Also set cutjas to
c 1/2 the shortest simulation cell lattice vector (inscribing sphere radius.
c If the input cutjas is smaller, it will be reset to the smaller value in read_input.
c However, cutjas is used not only for r_ee but also r_en, so for that purpose
c we should use shortest primitive cell lattice vector or sum over atoms in sim cell.
c Warning:  I need to fix the above:
c Also return rlenmin to set cutr to 1/2 the shortest lattice vector.  I think that is
c good enough -- no need to use 1/2 the shortest perpendicular distance.

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      parameter (eps=1.d-12)

      common /jaspar6/ cutjas,cutjasi,c1_jas6i,c1_jas6,c2_jas6,
     &asymp_r,asymp_jasa(MCTYPE),asymp_jasb(2)

      dimension rlatt(3,3)

      rlenmax=0
      rlenmin=9.d99
      do 20 i=1,3
        rlen=0
        do 10 k=1,3
   10     rlen=rlen+rlatt(k,i)**2
        if (rlen.gt.rlenmax) then
          rlenmax=max(rlen,rlenmax)
          imax=i
        endif
        if (rlen.lt.rlenmin) then
          rlenmin=min(rlen,rlenmin)
          imin=i
        endif
   20 continue
      rlenmax=sqrt(rlenmax)
      rlenmin=sqrt(rlenmin)
      cutr=rlenmin/2

c Warning: setting cutjas=rlenmin/2 for sim cell is OK for B terms, but not for A and C.
      if(isim_cell.eq.0) then
        write(6,'(''primitive  cell lattice vector'',i3,'' is longest ; length='',f8.3)')
     &  imax,rlenmax
        write(6,'(''primitive  cell lattice vector'',i3,'' is shortest; length='',f8.3)')
     &  imin,rlenmin
       else
        write(6,'(''simulation cell lattice vector'',i3,'' is longest ; length='',f8.3)')
     &  imax,rlenmax
        write(6,'(''simulation cell lattice vector'',i3,'' is shortest; length='',f8.3)')
     &  imin,rlenmin
        cutjas=rlenmin/2
      endif

c     if(cutjas.gt.rlenmin/2) then
c       write(6,'(''Warning: input cutjas > half shortest lattice vector;
c    &  cutjas reset from'',f9.5,'' to'',f9.5)') cutjas,rlenmin/2
c       cutjas=rlenmin/2
c     endif
c     cutjas=rlenmin/2

      do 40 i1=-1,1
        do 40 i2=-1,1
          do 40 i3=-1,1
            if((imax.eq.1.and.i1.ne.0).or.(imax.eq.2.and.i2.ne.0)
     &      .or.(imax.eq.3.and.i3.ne.0)) then
              rlen=0
              do 30 k=1,3
   30           rlen=rlen+(i1*rlatt(k,1)+i2*rlatt(k,2)+i3*rlatt(k,3))**2
              rlen=sqrt(rlen)
              if (rlen.lt.rlenmax-eps) then
                write(6,*) 'found shorter lattice vector'
                write(6,'(''i1,i2,i3,rlen='',3i3,f8.3)') i1,i2,i3,rlen
                write(6,'(''new rlatt='',3f8.3)')
     &          i1*rlatt(1,1)+i2*rlatt(1,2)+i3*rlatt(1,3),
     &          i1*rlatt(2,1)+i2*rlatt(2,2)+i3*rlatt(2,3),
     &          i1*rlatt(3,1)+i2*rlatt(3,2)+i3*rlatt(3,3)
                call fatal_error ('one can find shorter lattice vectors: see check_lattice')
              endif
            endif
   40 continue

      return
      end
c-----------------------------------------------------------------------

      subroutine reduce_sim_cell(r,rlatt,rlatt_inv)
c Written by Cyrus Umrigar
c For any electron position, replace it by the equivalent
c position in the simulation cell centered at the origin.
c r       = position in cartesian coords
c r_basis = position in lattice coords
c rlatt   = lattice vectors
c r       = rlatt * r_basis
c r_basis = rlatt_inv * r

      implicit real*8(a-h,o-z)

      dimension r(3),r_basis(3),rlatt(3,3),rlatt_inv(3,3)

c Find vector in basis coordinates
      do 20 k=1,3
        r_basis(k)=0
        do 10 i=1,3
   10     r_basis(k)=r_basis(k)+rlatt_inv(k,i)*r(i)
   20   r_basis(k)=r_basis(k)-nint(r_basis(k))

c     write(6,'(''r_basis'',9f9.4)') r_basis

c Convert back to cartesian coodinates
      do 30 k=1,3
        r(k)=0
        do 30 i=1,3
   30     r(k)=r(k)+rlatt(k,i)*r_basis(i)

      return
      end
c-----------------------------------------------------------------------

      subroutine find_sim_cell(r,rlatt_inv,r_basis,i_basis)
c Written by Cyrus Umrigar
c For any electron position, find its lattice coordinates
c r       = position in cartesian coords
c r_basis = position in lattice coords
c i_basis = which simulation cell it is in
c rlatt   = lattice vectors
c r       = rlatt * r_basis
c r_basis = rlatt_inv * r

      implicit real*8(a-h,o-z)

      dimension r(3),r_basis(3),i_basis(3),rlatt_inv(3,3)

c Find vector in basis coordinates
      do 20 k=1,3
        r_basis(k)=0
        do 10 i=1,3
   10     r_basis(k)=r_basis(k)+rlatt_inv(k,i)*r(i)
   20   i_basis(k)=nint(r_basis(k))

      return
      end
c-----------------------------------------------------------------------

      subroutine find_image(r,rlatt,rlatt_inv)
c Written by Cyrus Umrigar
c For any vector (from one particle to another) it finds the
c image that is closest.

      implicit real*8(a-h,o-z)

      dimension r(3),r_basis(3),rlatt(3,3),rlatt_inv(3,3)
     &,r1_try(3),r2_try(3),r3_try(3),i_sav(3),isign(3)

c Starting from a vector, which is a diff. of 2 vectors, each of which
c have been reduced to the central lattice cell, calculate
c a) its length
c b) sign along each of lattice directions

      r2=0
      do 20 k=1,3
        r2=r2+r(k)**2
        r_basis(k)=0
        do 10 i=1,3
   10     r_basis(k)=r_basis(k)+rlatt_inv(k,i)*r(i)
        if(abs(r_basis(k)).gt.1.d0) write(6,'(''**Warning, abs(r_basis)>1'')')
   20   isign(k)=nint(sign(1.d0,r_basis(k)))

      do 25 k=1,3
   25   i_sav(k)=0

c Check just 8, rather than 27, trapezoids
      do 60 i1=0,isign(1),isign(1)
        do 30 k=1,3
   30     r1_try(k)=r(k)-i1*rlatt(k,1)
        do 60 i2=0,isign(2),isign(2)
          do 40 k=1,3
   40       r2_try(k)=r1_try(k)-i2*rlatt(k,2)
          do 60 i3=0,isign(3),isign(3)
            r_try2=0
            do 50 k=1,3
              r3_try(k)=r2_try(k)-i3*rlatt(k,3)
   50         r_try2=r_try2+r3_try(k)**2
          if(r_try2.lt.r2) then
            i_sav(1)=i1
            i_sav(2)=i2
            i_sav(3)=i3
            r2=r_try2
          endif
   60 continue

c Replace r by its shortest image
      do 70 i=1,3
        do 70 k=1,3
   70     r(k)=r(k)-i_sav(i)*rlatt(k,i)

c     write(6,'(''rnew'',9f10.5)') (r(k),k=1,3),sqrt(r2)

c debug
c     r2_tmp=0
c     do 80 k=1,3
c  80  r2_tmp=r2_tmp+r(k)**2
c     if(r2_tmp.ne.r2) write(6,'(''r2,r2_tmp'',3d12.4)') r2,r2_tmp,r2-r2_tmp

      return
      end
c-----------------------------------------------------------------------

      subroutine find_image2(r,rlatt,r_basis1,r_basis2,i_basis1,i_basis2)
c Written by Cyrus Umrigar
c For any electron positions in lattice coordinates, it finds the
c image that is closest.
c Needs precomputed r_basis1,r_basis2,i_basis1,i_basis2.

      implicit real*8(a-h,o-z)

      dimension r(3),rlatt(3,3)
     &,r_basis1(3),r_basis2(3),i_basis1(3),i_basis2(3)
     &,r1_try(3),r2_try(3),r3_try(3),i_sav(3),isign(3)

c Find length of original vector and sign along each of lattice directions
      r2=0
      do 20 k=1,3
      r2=r2+r(k)**2
   20   isign(k)=int(sign(1.d0,r_basis2(k)-r_basis1(k)-i_basis2(k)+i_basis1(k)))

      do 25 k=1,3
   25   i_sav(k)=0

c Check just 8, rather than 27, trapezoids (not needed for orthorhombic lattice)
      do 60 i1=0,isign(1),isign(1)
        do 30 k=1,3
   30     r1_try(k)=r(k)-rlatt(k,1)*(i1+i_basis2(1)-i_basis1(1))
        do 60 i2=0,isign(2),isign(2)
          do 40 k=1,3
   40       r2_try(k)=r1_try(k)-rlatt(k,2)*(i2+i_basis2(2)-i_basis1(2))
          do 60 i3=0,isign(3),isign(3)
            r_try2=0
            do 50 k=1,3
              r3_try(k)=r2_try(k)-rlatt(k,3)*(i3+i_basis2(3)-i_basis1(3))
   50         r_try2=r_try2+r3_try(k)**2
          if(r_try2.lt.r2) then
            i_sav(1)=i1+i_basis2(1)-i_basis1(1)
            i_sav(2)=i2+i_basis2(2)-i_basis1(2)
            i_sav(3)=i3+i_basis2(3)-i_basis1(3)
            r2=r_try2
          endif
   60 continue

c Replace r by its shortest image
      do 70 i=1,3
        do 70 k=1,3
   70     r(k)=r(k)-rlatt(k,i)*i_sav(i)

      return
      end
c-----------------------------------------------------------------------

      subroutine find_image3(r,rnorm)
c Written by Cyrus Umrigar
c For any vector r (from one particle to another) it replaces the vector
c by its closest image and finds its norm

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'ewald.h'

      common /periodic/ rlatt(3,3),glatt(3,3),rlatt_sim(3,3),glatt_sim(3,3)
     &,rlatt_inv(3,3),rlatt_sim_inv(3,3),glatt_inv(3,3)
     &,cutr,cutr_sim,cutg,cutg_sim,cutg_big,cutg_sim_big
     &,igvec(3,NGVEC_BIGX),gvec(3,NGVEC_BIGX),gnorm(NGNORM_BIGX),igmult(NGNORM_BIGX)
     &,igvec_sim(3,NGVEC_SIM_BIGX),gvec_sim(3,NGVEC_SIM_BIGX),gnorm_sim(NGNORM_SIM_BIGX),igmult_sim(NGNORM_SIM_BIGX)
     &,rkvec_shift(3),kvec(3,IVOL_RATIO),rkvec(3,IVOL_RATIO),rknorm(IVOL_RATIO)
     &,k_inv(IVOL_RATIO),nband(IVOL_RATIO),ireal_imag(MORB)
     &,znuc_sum,znuc2_sum,vcell,vcell_sim
     &,ngnorm,ngvec,ngnorm_sim,ngvec_sim,ngnorm_orb,ngvec_orb,nkvec
     &,ngnorm_big,ngvec_big,ngnorm_sim_big,ngvec_sim_big
     &,ng1d(3),ng1d_sim(3),npoly,ncoef,np,isrange

      dimension r(3),r_basis(3)
     &,r1_try(3),r2_try(3),r3_try(3),i_sav(3),isign(3)

c Warning: tempor
      dimension rsav(3)
      do 5 k=1,3
    5   rsav(k)=r(k)

c a) reduce vector to central cell by expressing vector in lattice coordinates and
c    removing nint of it in each direction
c b) sign along each of lattice directions of vector reduced to central cell
      do 20 k=1,3
        r_basis(k)=0
        do 10 i=1,3
   10     r_basis(k)=r_basis(k)+rlatt_inv(k,i)*r(i)
        r_basis(k)=r_basis(k)-nint(r_basis(k))
   20   isign(k)=nint(sign(1.d0,r_basis(k)))

c Convert back to cartesian coodinates and find squared length
      r2=0
      do 23 k=1,3
        r(k)=0
        do 22 i=1,3
   22     r(k)=r(k)+rlatt(k,i)*r_basis(i)
   23   r2=r2+r(k)**2

      do 25 k=1,3
   25   i_sav(k)=0

c Check just 8, rather than 27, trapezoids (not needed for orthorhombic lattice)
      do 60 i1=0,isign(1),isign(1)
c     do 60 i1=-1,1,1
        do 30 k=1,3
   30     r1_try(k)=r(k)-i1*rlatt(k,1)
        do 60 i2=0,isign(2),isign(2)
c       do 60 i2=-1,1,1
          do 40 k=1,3
   40       r2_try(k)=r1_try(k)-i2*rlatt(k,2)
          do 60 i3=0,isign(3),isign(3)
c         do 60 i3=-1,1,1
            r_try2=0
            do 50 k=1,3
              r3_try(k)=r2_try(k)-i3*rlatt(k,3)
   50         r_try2=r_try2+r3_try(k)**2
          if(r_try2.lt.r2) then
            i_sav(1)=i1
            i_sav(2)=i2
            i_sav(3)=i3
            r2=r_try2
          endif
   60 continue

c Replace r by its shortest image
      rnorm=0
      do 80 k=1,3
        do 70 i=1,3
   70     r(k)=r(k)-rlatt(k,i)*i_sav(i)
   80   rnorm=rnorm+r(k)**2
      rnorm=sqrt(rnorm)

c     if(rnorm.gt.5.d0) write(6,'(''long'',6i2,10f8.4)')
c    &(isign(k),k=1,3),(i_sav(k),k=1,3),rnorm,(r(k),k=1,3),(rsav(k),k=1,3),(r_basis(k),k=1,3)

      return
      end
c-----------------------------------------------------------------------

      subroutine find_image4(rshift,r,rnorm)
c Written by Cyrus Umrigar
c For any vector r (from one particle to another) it replaces the vector
c by its closest image and finds its norm and the shift needed.

      implicit real*8(a-h,o-z)

      include 'vmc.h'
      include 'ewald.h'

      common /periodic/ rlatt(3,3),glatt(3,3),rlatt_sim(3,3),glatt_sim(3,3)
     &,rlatt_inv(3,3),rlatt_sim_inv(3,3),glatt_inv(3,3)
     &,cutr,cutr_sim,cutg,cutg_sim,cutg_big,cutg_sim_big
     &,igvec(3,NGVEC_BIGX),gvec(3,NGVEC_BIGX),gnorm(NGNORM_BIGX),igmult(NGNORM_BIGX)
     &,igvec_sim(3,NGVEC_SIM_BIGX),gvec_sim(3,NGVEC_SIM_BIGX),gnorm_sim(NGNORM_SIM_BIGX),igmult_sim(NGNORM_SIM_BIGX)
     &,rkvec_shift(3),kvec(3,IVOL_RATIO),rkvec(3,IVOL_RATIO),rknorm(IVOL_RATIO)
     &,k_inv(IVOL_RATIO),nband(IVOL_RATIO),ireal_imag(MORB)
     &,znuc_sum,znuc2_sum,vcell,vcell_sim
     &,ngnorm,ngvec,ngnorm_sim,ngvec_sim,ngnorm_orb,ngvec_orb,nkvec
     &,ngnorm_big,ngvec_big,ngnorm_sim_big,ngvec_sim_big
     &,ng1d(3),ng1d_sim(3),npoly,ncoef,np,isrange

      dimension r(3),r_basis(3),rshift(3)
     &,r1_try(3),r2_try(3),r3_try(3),i_sav(3),isign(3)

c a) reduce vector to central cell by expressing vector in lattice coordinates and
c    removing nint of it in each direction
c b) sign along each of lattice directions of vector reduced to central cell
c Note: rhift is just a work array here; calculated for real only at end.
      do 20 k=1,3
        r_basis(k)=0
        do 10 i=1,3
   10     r_basis(k)=r_basis(k)+rlatt_inv(k,i)*r(i)
        rshift(k)=r_basis(k)-nint(r_basis(k))
   20   isign(k)=nint(sign(1.d0,rshift(k)))

c Convert back to cartesian coodinates and find squared length
      r2=0
      do 23 k=1,3
        r(k)=0
        do 22 i=1,3
   22     r(k)=r(k)+rlatt(k,i)*rshift(i)
   23   r2=r2+r(k)**2

      do 25 k=1,3
   25   i_sav(k)=0

c Check just 8, rather than 27, trapezoids (not needed for orthorhombic lattice)
      do 60 i1=0,isign(1),isign(1)
        do 30 k=1,3
   30     r1_try(k)=r(k)-i1*rlatt(k,1)
        do 60 i2=0,isign(2),isign(2)
          do 40 k=1,3
   40       r2_try(k)=r1_try(k)-i2*rlatt(k,2)
          do 60 i3=0,isign(3),isign(3)
            r_try2=0
            do 50 k=1,3
              r3_try(k)=r2_try(k)-i3*rlatt(k,3)
   50         r_try2=r_try2+r3_try(k)**2
          if(r_try2.lt.r2) then
            i_sav(1)=i1
            i_sav(2)=i2
            i_sav(3)=i3
            r2=r_try2
          endif
   60 continue

c Replace r by its shortest image and calculate rshift
      rnorm=0
      do 80 k=1,3
        rshift(k)=0
        do 70 i=1,3
          rshift(k)=rshift(k)+rlatt(k,i)*(nint(r_basis(i))+i_sav(i))
   70     r(k)=r(k)-rlatt(k,i)*i_sav(i)
   80   rnorm=rnorm+r(k)**2
      rnorm=sqrt(rnorm)

      return
      end
