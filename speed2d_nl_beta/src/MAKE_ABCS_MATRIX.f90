!    Copyright (C) 2014 The SPEED FOUNDATION
!    Author: Ilario Mazzieri
!
!    This file is part of SPEED.
!
!    SPEED is free software; you can redistribute it and/or modify it
!    under the terms of the GNU Affero General Public License as
!    published by the Free Software Foundation, either version 3 of the
!    License, or (at your option) any later version.
!
!    SPEED is distributed in the hope that it will be useful, but
!    WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
!    Affero General Public License for more details.
!
!    You should have received a copy of the GNU Affero General Public License
!    along with SPEED.  If not, see <http://www.gnu.org/licenses/>.

!> @brief Computes ABC matrices in CRS format. 
!! @author Ilario Mazzieri
!> @date April, 2014
!> @version 1.0


!> @param[in] nnod number of nodes
!> @param[in] length nnzero elements in ABC matrices
!> @param[in] nelem number of element
!> @param[in] nelem_abc number of abc element
!> @param[in] ielem_abc element having an ab edge
!> @param[in] nedge_abc number of ab edges
!> @param[in] iedge_abc index of the ab edge (1,2,3,4)
!> @param[in] cs_nnz_bc legnth of cs_bc
!> @param[in] cs_bc vector for boundary connectivity
!> @param[in] cs_nnz length of cs 
!> @param[in] cs vector for grid connectivity
!> @param[in] nm number of materials
!> @param[in] tag_mat label for materials
!> @param[in] prop_mat material properties
!> @param[in] sd polynomial degree
!> @param[in] alfa1/2,beta1/2,gamma1/2 parameter for coordinate transformation
!> @param[in] xx_spx, yy_spx coordinate of spectral nodes
!> @param[out] I_ABC,J_ABC,M_ABC_U,M_ABC_V Abc matrices in CRS format


      subroutine MAKE_ABCS_MATRIX(nnod,length,I_ABC,J_ABC,M_ABC_U,M_ABC_V, &
                             nelem, nelem_abc, ielem_abc, nedge_abc, iedge_abc, & 
                             cs_nnz_bc, cs_bc, cs_nnz,cs, nm, tag_mat, prop_mat, sd, &
                             alfa1, alfa2, beta1, beta2, gamma1, gamma2, xx_spx, yy_spx)     
     
     
      implicit none
      integer*4 :: nelem, cs_nnz,nm,nn, i, s, r, ll, n,m, kk, k, ind_c
      integer*4 :: in, is, it, j,h, icol1, icol2, ie, im, jm, lenght
      integer*4 :: iedge, ied1, ied2, iel1, iel2, iel3, iel4
      integer*4 :: edge_ia, edge_ib, edge_ja, edge_jb, inq, inp
      integer*4 :: irow1, irow2, nnod, length, nelem_abc, nedge_abc, cs_nnz_bc
      integer*4, dimension(nm) :: tag_mat, sd
      real*8, dimension(nm,4) :: prop_mat
      integer*4, dimension(0:cs_nnz) :: cs
      integer*4, dimension(0:cs_nnz_bc) :: cs_bc
      integer*4, dimension(0:2*nnod) :: I_ABC
      integer*4, dimension(length) :: J_ABC
      integer*4, dimension(nelem_abc) :: ielem_abc
      integer*4, dimension(nedge_abc) :: iedge_abc      
      
      real*8 :: rho, lambda, mu, edge_lx, edge_ly, edge_ll
      real*8 :: edge_nx, edge_ny, v_beta, v_alpha
      real*8 :: delta_mi, delta_ri, delta_nj, delta_sj
      real*8 :: delta_mpp, delta_ms, delta_nqq, delta_nr, delta_pps, delta_qqr
      real*8, dimension(nelem) :: alfa1, alfa2, beta1, beta2, gamma1, gamma2
      real*8, dimension(length) ::  M_ABC_U, M_ABC_V
      real*8, dimension(nnod) :: xx_spx, yy_spx
      real*8, dimension(:), allocatable :: ct, ww
      real*8, dimension(:), allocatable :: dxdx_el, dxdy_el, dydx_el, dydy_el
      real*8, dimension(:,:), allocatable :: dd, det_j
      
      real*8, dimension(:,:), allocatable :: mat_A,mat_B,mat_C

      

      do k = 1,nelem_abc
         
          ie = ielem_abc(k)
          iedge = iedge_abc(k)
          im = cs(cs(ie -1) +0);

          rho = prop_mat(im,1)
          lambda = prop_mat(im,2)
          mu = prop_mat(im,3)
               
          v_alpha = dsqrt(lambda+2*mu)/dsqrt(rho)
          v_beta = dsqrt(mu)/dsqrt(rho)

          nn = sd(im) + 1


          allocate(ct(nn),ww(nn),dd(nn,nn))
          allocate(dxdx_el(nn),dxdy_el(nn),dydx_el(nn),dydy_el(nn))
	  allocate(det_j(nn,nn))				
          call LGL(nn,ct,ww,dd)
            
          ied1 = cs_bc(cs_bc(iedge -1) +1)
          ied2 = cs_bc(cs_bc(iedge) -1)
                        
                        
          iel1 = cs(cs(ie -1) +1)
          iel2 = cs(cs(ie -1) +nn)
          iel3 = cs(cs(ie -1) +nn*nn)
          iel4 = cs(cs(ie -1) +nn*(nn -1) +1)
                        
          !write(*,*) ied1, ied2
          !write(*,*) iel1, iel2, iel3, iel4
          !read(*,*)              
                        
! First edge
          if (((ied1.eq.iel1).and.(ied2.eq.iel2)).or.((ied2.eq.iel1).and.(ied1.eq.iel2))) then
             edge_lx = xx_spx(iel2) - xx_spx(iel1)
             edge_ly = yy_spx(iel2) - yy_spx(iel1)
             edge_ll = dsqrt(edge_lx*edge_lx + edge_ly*edge_ly)
             edge_nx = edge_ly / edge_ll
             edge_ny = -1.0d0 * edge_lx / edge_ll
             edge_ia = 1; edge_ib = nn
             edge_ja = 1; edge_jb = 1
          endif
                        
! Second edge
          if (((ied1.eq.iel2).and.(ied2.eq.iel3)).or.((ied2.eq.iel2).and.(ied1.eq.iel3))) then
             edge_lx = xx_spx(iel3) - xx_spx(iel2)
             edge_ly = yy_spx(iel3) - yy_spx(iel2)
             edge_ll = dsqrt(edge_lx*edge_lx + edge_ly*edge_ly)
             edge_nx = edge_ly / edge_ll
             edge_ny = -1.0d0 * edge_lx / edge_ll
             edge_ia = nn; edge_ib = nn
             edge_ja = 1;  edge_jb = nn
          endif
                        
! Third edge
          if (((ied1.eq.iel3).and.(ied2.eq.iel4)).or.((ied2.eq.iel3).and.(ied1.eq.iel4))) then
             edge_lx = xx_spx(iel4) - xx_spx(iel3)
             edge_ly = yy_spx(iel4) - yy_spx(iel3)
             edge_ll = dsqrt(edge_lx*edge_lx + edge_ly*edge_ly)
             edge_nx = edge_ly / edge_ll; 
             edge_ny = -1.0d0 * edge_lx / edge_ll
             edge_ia = 1;  edge_ib = nn
             edge_ja = nn; edge_jb = nn
          endif
                        
! Fourth edge
          if (((ied1.eq.iel4).and.(ied2.eq.iel1)).or.((ied2.eq.iel4).and.(ied1.eq.iel1))) then
             edge_lx = xx_spx(iel1) - xx_spx(iel4)
             edge_ly = yy_spx(iel1) - yy_spx(iel4)
             edge_ll = dsqrt(edge_lx*edge_lx + edge_ly*edge_ly)
             edge_nx = edge_ly / edge_ll
             edge_ny = -1.0d0 * edge_lx / edge_ll
             edge_ia = 1; edge_ib = 1
             edge_ja = 1; edge_jb = nn
          endif
                        
                        
          do i = 1,nn
             dxdy_el(i) = beta1(ie) + gamma1(ie) * ct(i)
             dydy_el(i) = beta2(ie) + gamma2(ie) * ct(i)
          enddo
                        
          do j = 1,nn
             dxdx_el(j) = alfa1(ie) + gamma1(ie) * ct(j)
             dydx_el(j) = alfa2(ie) + gamma2(ie) * ct(j)
          enddo

          do j = 1,nn
             do i = 1,nn
                det_j(i,j) = dxdx_el(j)*dydy_el(i) - dxdy_el(i)*dydx_el(j)
             enddo
          enddo 
 
          !write(*,*) det_j
          !read(*,*)
 
          allocate(mat_A(nn**2,nn**2),mat_B(nn**2,nn**2),mat_C(nn**2,nn**2))

          mat_A = 0.d0;      mat_B = 0.d0;     mat_C = 0.d0;
            
          do r = 1, nn 
             do s = 1, nn
                ll = (r-1)*nn + s 
                   
                in = cs(cs(ie -1) + ll)
                irow1 = in
                  
                                     
                do n = 1, nn
                   do m = 1, nn
                      kk = (n-1)*nn +m               
                   
                      jm = cs(cs(ie -1) + kk)
                      icol1 = jm

                        
                      if(edge_ja .eq. edge_jb .and. edge_ja .eq. 1) then
                          inq = 1
                          inp = 0
                      elseif(edge_ja .eq. edge_jb .and. edge_ja .eq. nn) then
                          inq = nn
                          inp = 0
                      elseif(edge_ia .eq. edge_ib .and. edge_ia .eq. 1) then 
                          inp = 1
                          inq = 0                                              
                      elseif(edge_ia .eq. edge_ib .and. edge_ia .eq. nn) then
                          inp = nn
                          inq = 0                        
                      endif 

                      if(m.eq.s) then 
                          delta_ms = 1.d0
                      else 
                          delta_ms = 0.d0
                      endif
             
                      if(n.eq.r) then 
                          delta_nr = 1.d0
                      else 
                          delta_nr = 0.d0
                      endif
                           
                      if(inp.eq.s) then 
                          delta_pps = 1.d0
                      else 
                          delta_pps = 0.d0
                      endif
             
                      if(inq.eq.r) then 
                          delta_qqr = 1.d0
                      else 
                          delta_qqr = 0.d0
                      endif

                      if(m.eq.inp) then 
                          delta_mpp = 1.d0
                      else 
                          delta_mpp = 0.d0
                      endif
             
                      if(n.eq.inq) then 
                          delta_nqq = 1.d0
                      else 
                          delta_nqq = 0.d0
                      endif

                           
                           
                      if(edge_ja .eq. edge_jb) then 

                           mat_A(ll,kk) =  edge_ll/2.d0 *ww(s)*delta_qqr*(1.d0/det_j(s,r)) &
                                         * (dydy_el(s)*dd(s,m)*delta_nr - dydx_el(r)*dd(r,n)*delta_ms )  
                                
                           mat_B(ll,kk) = edge_ll/2.d0 *ww(s)*delta_qqr*(1.d0/det_j(s,r)) &
                                         * (dxdx_el(r)*dd(r,n)*delta_ms - dxdy_el(s)*dd(s,m)*delta_nr )
                                             
                           mat_C(ll,kk) = edge_ll/2.d0 *ww(s)*delta_ms*delta_qqr*delta_nqq
                             
                       else
                          
                          
                           mat_A(ll,kk) =  edge_ll/2.d0 *ww(r)*delta_pps*(1.d0/det_j(s,r)) &
                                        * (dydy_el(s)*dd(s,m)*delta_nr - dydx_el(r)*dd(r,n)*delta_ms )  
                                
                           mat_B(ll,kk) = edge_ll/2.d0 *ww(r)*delta_pps*(1.d0/det_j(s,r)) &
                                        * (dxdx_el(r)*dd(r,n)*delta_ms - dxdy_el(s)*dd(s,m)*delta_nr )
                                             
                           mat_C(ll,kk) = edge_ll/2.d0 *ww(r)*delta_nr*delta_pps*delta_mpp

                               
                        endif
                               

                  enddo
                enddo
                 
            enddo
          enddo

          do j = 1,nn
             do i = 1,nn
                is = nn*(j -1) + i
                in = cs(cs(ie -1) + is)
                
                irow1 = in
                irow2 = in + nnod

                do n = 1,nn
                   do m = 1,nn
                      it = nn*(n -1) + m
                      jm = cs(cs(ie -1) + it)

                      icol1 = jm
                      icol2 = jm + nnod

                      call FIND_POSITION(J_ABC, length, I_ABC(irow1-1) + 1, I_ABC(irow1), icol1, ind_c)  ! ATT        
        
                      M_ABC_U(ind_c) = M_ABC_U(ind_c) &
                        +(mu*(2.d0*v_beta-v_alpha)/v_beta + (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha ) &
                                 *edge_nx*edge_ny**2.d0 * mat_A(is,it) &
                        -(mu*(2.d0*v_beta-v_alpha)/v_beta + (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha ) &
                                  *edge_ny*edge_nx**2.d0 * mat_B(is,it) 

                      M_ABC_V(ind_c) = M_ABC_V(ind_c) + &
                               (-mu/v_beta * edge_ny*edge_ny - (lambda+2.d0*mu)/v_alpha * edge_nx*edge_nx) * mat_C(is,it)



                      call FIND_POSITION(J_ABC, length, I_ABC(irow1-1) + 1, I_ABC(irow1), icol2, ind_c)
        
                      M_ABC_U(ind_c) = M_ABC_U(ind_c) &
                        +(mu*(2.d0*v_beta-v_alpha)/v_beta * edge_nx**3.d0 - & 
                           (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha *edge_ny*edge_nx**2.d0 ) *mat_A(is,it) &
                        -(mu*(2.d0*v_beta-v_alpha)/v_beta*edge_nx*edge_ny**2.d0 - &
                           (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha *edge_nx**3.d0 ) * mat_B(is,it) 

                      M_ABC_V(ind_c) = M_ABC_V(ind_c) + &
                               (mu/v_beta * edge_nx*edge_ny - (lambda+2.d0*mu)/v_alpha * edge_nx*edge_ny) * mat_C(is,it)
        
        
                     call FIND_POSITION(J_ABC, length, I_ABC(irow2-1) + 1, I_ABC(irow2), icol1, ind_c)
        
                     M_ABC_U(ind_c) = M_ABC_U(ind_c)  &
                      -(mu*(2.d0*v_beta-v_alpha)/v_beta*edge_ny*edge_nx**2.d0 - &
                          (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha *edge_ny**3.d0 ) *mat_A(is,it) &
                      +(mu*(2.d0*v_beta-v_alpha)/v_beta*edge_nx**3.d0 - &
                          (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha *edge_nx*edge_ny**2.d0 ) * mat_B(is,it) 

                     M_ABC_V(ind_c) = M_ABC_V(ind_c) + &
                               (mu/v_beta * edge_nx*edge_ny - (lambda+2.d0*mu)/v_alpha * edge_nx*edge_ny) * mat_C(is,it)
                               

                     call FIND_POSITION(J_ABC, length, I_ABC(irow2-1) + 1, I_ABC(irow2), icol2, ind_c)
        
                     M_ABC_U(ind_c) = M_ABC_U(ind_c)  &
                      -(mu*(2.d0*v_beta-v_alpha)/v_beta + (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha ) &
                                                   *edge_nx*edge_ny**2.d0 * mat_A(is,it) &
                      +(mu*(2.d0*v_beta-v_alpha)/v_beta + (lambda*v_beta + 2.d0*mu*(v_beta-v_alpha))/v_alpha ) &
                                                   *edge_ny*edge_nx**2.d0 * mat_B(is,it) 
                                  
                     M_ABC_V(ind_c) = M_ABC_V(ind_c)+ &
                               (-mu/v_beta * edge_nx*edge_nx - (lambda+2.d0*mu)/v_alpha * edge_ny*edge_ny) * mat_C(is,it)
                                      
                   enddo
                enddo
             enddo
          enddo


          deallocate(mat_A,mat_B,mat_C)
  	  deallocate(ct,ww,dd)
      	  deallocate(dxdx_el,dxdy_el,dydx_el,dydy_el)
	  deallocate(det_j)

                     
       enddo




       end subroutine MAKE_ABCS_MATRIX
