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

!> @brief Creates data structure for dg elements.
!! @author Ilario Mazzieri
!> @date April, 2014
!> @version 1.0

!> @param[in] nm number of materials
!> @param[in] sd polynomial degree vector
!> @param[in] tag_mat  materials label
!> @param[in] prop_mat material properties rho, lambda, mu, gamma
!> @param[in] cs_nnz_loc length of cs_loc
!> @param[in] cs_loc local spectral connectivity vector
!> @param[in] nn_loc number of nodes
!> @param[in] ne_loc number of elements
!> @param[in] xs x-coordinate of GLL nodes
!> @param[in] ys y-coordinate of GLL nodes
!> @param[in] nel_dg_loc  number of dg elements
!> @param[in] i4count  i4count(i) = 1 if the i-th node belongs to a
!!                         dg surface
!> @param[in] alfa1 costant values for the bilinear map
!> @param[in] alfa2 costant values for the bilinear map
!> @param[in] beta1 costant values for the bilinear map 
!> @param[in] beta2 costant values for the bilinear map
!> @param[in] gamma1 costant values for the bilinear map
!> @param[in] gamma2 costant values for the bilinear map
!> @param[in] delta1 costant values for the bilinear map
!> @param[in] delta2 costant values for the bilinear map
!> @param[in] dg_cnst  -1 = SIPG, 0 = IIPG, 1 = NIPG
!> @param[in] penalty_c  penalty constant
!> @param[in] faces  identification of dg surface: faces(1,i) = material,
!!                                             faces(2,i) = element,
!!                                             faces(3,i) = face.
!> @param[in] area_nodes  area_nodes(1,i) area of the face i, 
!!                    area_nodes(2,i),...,area_nodes(9,i) constants for the bilinear map
!> @param[in] filename file name (DGFS.input) where DG info are written 
!> @param[out] el_new  data structure for dg elements

   subroutine MAKE_DG_INTERFACE(nm, sd, tag_mat, prop_mat, cs_nnz_loc, cs_loc, &
                           nn_loc, ne_loc, &
                           xs, ys,&
                           nel_dg_loc, i4count, &
                           alfa1, alfa2, &
                           beta1, beta2, &
                           gamma1, gamma2, &
                           delta1, delta2, dg_cnst, penalty_c, &
                           faces, area_nodes, el_new, filename, test)


     use max_var
     use str_mesh_after 
     use DGJUMP

     implicit none
  
     type(ELEMENT_after), dimension(:), allocatable :: dg_els
     type(el4loop), dimension(nel_dg_loc), intent(inout):: el_new                        
 
     character*70 :: filename

     integer*4 :: ishift, jshift, test
     integer*4 :: im, nn, ie, ned, ip, mm, nnz, nnz_p, nnz_m, nnz_p_only_uv, nnz_m_only_uv
     integer*4 :: ne1, ne2, ic1, ic2
     
     integer*4 :: nm, cs_nnz_loc, nn_loc, ne_loc, nel_dg_loc, nel_dg_glo
     integer*4 :: n_line, ielem, iface, iene, ifacene, imne
     integer*4 :: int_trash, statuss, i, tt, ih, it, p, j,k
     integer*4 :: unitname

     integer*4 :: nofne_el, ic

     integer*4, dimension(nm) :: tag_mat, sd
     integer*4, dimension(0:cs_nnz_loc) :: cs_loc
     integer*4, dimension(nn_loc) :: local_n_num, i4count
     integer*4, dimension(ne_loc) :: local_el_num
     
     integer*4, dimension(:), allocatable :: I4S, J4S     

     integer*4, dimension(:,:), allocatable :: con_DG
     integer*4, dimension(:,:), allocatable :: copia
     integer*4, dimension(3,nel_dg_loc) :: faces

     real*8 :: real_trash, lambda, mu, pen_p, pen_h, pen, penalty_c, dg_cnst
     real*8 :: cp_a, cp_b, cp_c, cp_d, cp_e, cp_f, cp_g, cp_n, cp_p
     real*8 :: csi, eta, normal_x, normal_y
     
     real*8 :: c_alfa1, c_alfa2, c_beta1, c_beta2
     real*8 :: c_gamma1, c_gamma2, c_delta1, c_delta2

     real*8, dimension(ne_loc) :: alfa1,alfa2
     real*8, dimension(ne_loc) :: beta1,beta2
     real*8, dimension(ne_loc) :: gamma1,gamma2
     real*8, dimension(ne_loc) :: delta1,delta2
     
     real*8, dimension(:), allocatable :: M4S

     real*8, dimension(:,:), allocatable :: nodes_DG
     real*8, dimension(:,:), allocatable :: JP,JM, JP_only_uv,JM_only_uv
     real*8, dimension(nn_loc) :: xs,ys
     real*8, dimension(nm,4) :: prop_mat
     real*8, dimension(9,nel_dg_loc) :: area_nodes
     real*8 :: scratch
     integer*4 :: ios
     
      real*8 :: c11,c33,c55,c13,c15,c35
      real*8 :: c11p,c33p,c55p,c13p,c15p,c35p
      real*8 :: c11m,c33m,c55m,c13m,c15m,c35m     

     unitname = 50
     open(unitname,file=filename)
     n_line = 0
     do
        read(unitname,*,iostat=ios) scratch,scratch,scratch,scratch,scratch,&
                                    scratch,scratch,scratch,scratch,scratch
        
        if(ios /= 0) exit
        n_line = n_line + 1

     enddo
     close(unitname)
     
     
     open(unitname,file=filename)
      
     
     allocate(con_DG(6,2*n_line), nodes_DG(4,2*n_line))
     con_DG = 0
     nodes_DG = 0.d0
     
     
     do i = 1, n_line
        read(unitname,*) con_DG(1,i), con_DG(2,i), con_DG(3,i), con_DG(4,i), con_DG(5,i), con_DG(6,i), & 
                          nodes_DG(1,i), nodes_DG(2,i), nodes_DG(3,i), nodes_DG(4,i)
     enddo


     close(unitname)


     do i = 1, 3
        con_DG(i, n_line+1: 2*n_line) = con_DG(3+i,1:n_line)
     enddo  

     do i = 1, 3
        con_DG(3+i, n_line+1: 2*n_line) = con_DG(i,1:n_line)
     enddo  

     do i = 1, 4
        nodes_DG(i, n_line+1: 2*n_line) = nodes_DG(i,1:n_line)       
     enddo

     allocate(dg_els(nel_dg_loc))

!***************************************************************************************************************
     nel_dg_glo = nel_dg_loc
     nel_dg_loc = 0      
     ned = cs_loc(0) - 1


      do im = 1,nm

         nn = sd(im) +1         

         do ie = 1,ned
            if (cs_loc(cs_loc(ie -1) + 0) .eq. tag_mat(im)) then
       
               !1st edge
               ne1 = cs_loc(cs_loc(ie -1) +1)
               ne2 = cs_loc(cs_loc(ie -1) +nn)                                         
                           
               if ((i4count(ne1).ne.0) .and. (i4count(ne2).ne.0) ) then

                  ip = 0  
                  nel_dg_loc = nel_dg_loc + 1                        
                  dg_els(nel_dg_loc)%ind_el = ie
                  dg_els(nel_dg_loc)%face_el = 1
                  dg_els(nel_dg_loc)%mat = tag_mat(im)
                  dg_els(nel_dg_loc)%spct_deg = nn-1
                  dg_els(nel_dg_loc)%quad_rule = ip

                  i = 1
                  do  while (i .le. 2*n_line) 
                  
                    if(con_DG(2,i) .eq. ie .and. con_DG(3,i) .eq. 1) then 
                    
                    
                      ip = ip + 1
                      dg_els(nel_dg_loc)%quad_rule = ip
                      
                      call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        alfa1(ie),alfa2(ie), &
                                        beta1(ie),beta2(ie), &
                                        gamma1(ie),gamma2(ie), &
                                        delta1(ie),delta2(ie), & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i), con_DG(5,i), 1.d-6, 1.01d0,1)
                                        
                                        
                        dg_els(nel_dg_loc)%x_pl(ip) = csi
                        dg_els(nel_dg_loc)%y_pl(ip) = -1.d0
                        dg_els(nel_dg_loc)%wx_pl(ip) = nodes_DG(3,i)
                        dg_els(nel_dg_loc)%wy_pl(ip) = nodes_DG(4,i)
                        
                        dg_els(nel_dg_loc)%omega_minus(ip,0) = con_DG(4,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,1) = con_DG(5,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,2) = con_DG(6,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,3) = 0 
                         
                         
                         ! find the corresponding neigh. elem in faces matrix
                         
                         call GET_FACE_DG(faces, nel_dg_glo, con_DG(5,i), con_DG(6,i), ih)
                         
                         call MAKE_BILINEAR_MAP(area_nodes(2:9,ih), &
                                             c_alfa1, c_alfa2, c_beta1, c_beta2, & 
                                             c_gamma1, c_gamma2, c_delta1, c_delta2)
                         
                                                  
                         call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        c_alfa1, c_alfa2, &
                                        c_beta1, c_beta2, & 
                                        c_gamma1, c_gamma2, &
                                        c_delta1, c_delta2, & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i),con_DG(5,i), 1.d-6, 1.01d0,1)   
                                        
                         select case(con_DG(6,i))    
                            case(1)
                              eta = -1.d0
                            case(2)
                              csi = 1.d0
                            case(3)
                              eta = 1.d0
                            case(4)
                              csi = -1.d0
                            case default
                              write(*,*) 'error in make_interface'
                            end select             

                         dg_els(nel_dg_loc)%x_mn(ip) =  csi
                         dg_els(nel_dg_loc)%y_mn(ip) =  eta

                        endif
                        i = i + 1
                         
                  enddo
                 
                   call MAKE_NORMAL(1,xs(ne1), xs(ne2), ys(ne1), ys(ne2), normal_x, normal_y)

                   dg_els(nel_dg_loc)%nx = normal_x
                   dg_els(nel_dg_loc)%ny = normal_y


               endif  
               
                            
               !2nd edge 
               ne1 = cs_loc(cs_loc(ie -1) +nn)             
               ne2 = cs_loc(cs_loc(ie -1) +nn*nn)
                            
               if ((i4count(ne1).ne.0) .and. (i4count(ne2).ne.0)) then
 
                  !face 2: x = 1
                  ip = 0
                  nel_dg_loc = nel_dg_loc +1
                  dg_els(nel_dg_loc)%ind_el = ie
                  dg_els(nel_dg_loc)%face_el = 2
                  dg_els(nel_dg_loc)%mat = tag_mat(im)
                  dg_els(nel_dg_loc)%spct_deg = nn-1
                  dg_els(nel_dg_loc)%quad_rule = ip
                  i = 1


                  do  while (i .le. 2*n_line) 
                  
                    if(con_DG(2,i) .eq. ie .and. con_DG(3,i) .eq. 2) then 

                      ip = ip + 1
                      dg_els(nel_dg_loc)%quad_rule = ip
                      
                      !write(*,*) nodes_DG(1,i), nodes_DG(2,i)
                      
                      call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        alfa1(ie),alfa2(ie), &
                                        beta1(ie),beta2(ie), &
                                        gamma1(ie),gamma2(ie), &
                                        delta1(ie),delta2(ie), & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i), con_DG(5,i), 1.d-6, 1.01d0,1)
                                       
                        dg_els(nel_dg_loc)%x_pl(ip) = 1.d0
                        dg_els(nel_dg_loc)%y_pl(ip) = eta                       
                        dg_els(nel_dg_loc)%wx_pl(ip) = nodes_DG(3,i)
                        dg_els(nel_dg_loc)%wy_pl(ip) = nodes_DG(4,i)
                        
                        dg_els(nel_dg_loc)%omega_minus(ip,0) = con_DG(4,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,1) = con_DG(5,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,2) = con_DG(6,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,3) = 0 
                                                  
                         
                         ! find the corresponding neigh. elem in faces matrix
                         call GET_FACE_DG(faces, nel_dg_glo, con_DG(5,i), con_DG(6,i), ih)
                         
                         
                         call MAKE_BILINEAR_MAP(area_nodes(2:9,ih), &
                                             c_alfa1, c_alfa2, c_beta1, c_beta2, & 
                                             c_gamma1, c_gamma2, c_delta1, c_delta2)
                                             
                         call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        c_alfa1, c_alfa2, &
                                        c_beta1, c_beta2, & 
                                        c_gamma1, c_gamma2, &
                                        c_delta1, c_delta2, & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i),con_DG(5,i), 1.d-6, 1.01d0,1)   
                                        
                                        
                         select case(con_DG(6,i))    
                            case(1)
                              eta = -1.d0
                            case(2)
                              csi = 1.d0
                            case(3)
                              eta = 1.d0
                            case(4)
                              csi = -1.d0
                            case default
                              write(*,*) 'error in make_interface'
                            end select             

                         dg_els(nel_dg_loc)%x_mn(ip) =  csi
                         dg_els(nel_dg_loc)%y_mn(ip) =  eta
                     
                     endif 
                       
                         i = i+1                    
                         
                  enddo
 
                   call MAKE_NORMAL(2,xs(ne1), xs(ne2), ys(ne1), ys(ne2), normal_x, normal_y)

                   dg_els(nel_dg_loc)%nx = normal_x
                   dg_els(nel_dg_loc)%ny = normal_y


               endif  
               
                            
               !3rd edge
               ne1 = cs_loc(cs_loc(ie -1) +nn*nn)
               ne2 = cs_loc(cs_loc(ie -1) +nn*(nn -1) +1)
      
               if ((i4count(ne1).ne.0) .and. (i4count(ne2).ne.0)) then

                  !face 3: y = 1
                  ip = 0
                  nel_dg_loc = nel_dg_loc +1
                  dg_els(nel_dg_loc)%ind_el = ie
                  dg_els(nel_dg_loc)%face_el = 3
                  dg_els(nel_dg_loc)%mat = tag_mat(im)
                  dg_els(nel_dg_loc)%spct_deg = nn-1
                  dg_els(nel_dg_loc)%quad_rule = ip
                  
                  i = 1

                  do  while (i .le. 2*n_line) 
                  
                    if(con_DG(2,i) .eq. ie .and. con_DG(3,i) .eq. 3) then 


                      ip = ip + 1
                      dg_els(nel_dg_loc)%quad_rule = ip
                      
                      call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        alfa1(ie),alfa2(ie), &
                                        beta1(ie),beta2(ie), &
                                        gamma1(ie),gamma2(ie), &
                                        delta1(ie),delta2(ie), & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i), con_DG(5,i), 1.d-6, 1.01d0,1)
                                        
                                        
                                        
                        dg_els(nel_dg_loc)%x_pl(ip) = csi
                        dg_els(nel_dg_loc)%y_pl(ip) = 1.d0
                        dg_els(nel_dg_loc)%wx_pl(ip) = nodes_DG(3,i)
                        dg_els(nel_dg_loc)%wy_pl(ip) = nodes_DG(4,i)
                                             
                        dg_els(nel_dg_loc)%omega_minus(ip,0) = con_DG(4,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,1) = con_DG(5,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,2) = con_DG(6,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,3) = 0 
                         
                         
                        ! find the corresponding neigh. elem in faces matrix
                                                 
                         call GET_FACE_DG(faces, nel_dg_glo, con_DG(5,i), con_DG(6,i), ih)
                         
                         call MAKE_BILINEAR_MAP(area_nodes(2:9,ih), &
                                             c_alfa1, c_alfa2, c_beta1, c_beta2, & 
                                             c_gamma1, c_gamma2, c_delta1, c_delta2)
                         
                                                  
                         call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        c_alfa1, c_alfa2, &
                                        c_beta1, c_beta2, & 
                                        c_gamma1, c_gamma2, &
                                        c_delta1, c_delta2, & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i),con_DG(5,i), 1.d-6, 1.01d0,1)   
                                        
                         select case(con_DG(6,i))    
                            case(1)
                              eta = -1.d0
                            case(2)
                              csi = 1.d0
                            case(3)
                              eta = 1.d0
                            case(4)
                              csi = -1.d0
                            case default
                              write(*,*) 'error in make_interface'
                            end select             

                         dg_els(nel_dg_loc)%x_mn(ip) =  csi
                         dg_els(nel_dg_loc)%y_mn(ip) =  eta
                     
                       endif 
                       i = i +1
                                             
                         
                  enddo

                   call MAKE_NORMAL(3,xs(ne1), xs(ne2), ys(ne1), ys(ne2), normal_x, normal_y)

                   dg_els(nel_dg_loc)%nx = normal_x
                   dg_els(nel_dg_loc)%ny = normal_y

             endif  
                          
               !4th edge
               ne1 = cs_loc(cs_loc(ie -1) +1)
               ne2 = cs_loc(cs_loc(ie -1) +nn*(nn -1) +1)
                            
               if ((i4count(ne1).ne.0) .and. (i4count(ne2).ne.0)) then
                  
                  !face 4 : x = -1
                  ip = 0
                  nel_dg_loc = nel_dg_loc +1             
                  dg_els(nel_dg_loc)%ind_el = ie
                  dg_els(nel_dg_loc)%face_el = 4
                  dg_els(nel_dg_loc)%mat = tag_mat(im)
                  dg_els(nel_dg_loc)%spct_deg = nn-1
                  dg_els(nel_dg_loc)%quad_rule = ip
                  i = 1

                  do  while (i .le. 2*n_line) 
                  
                    if(con_DG(2,i) .eq. ie .and. con_DG(3,i) .eq. 4) then 


                      ip = ip + 1
                      dg_els(nel_dg_loc)%quad_rule = ip
                      
                      call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        alfa1(ie),alfa2(ie), &
                                        beta1(ie),beta2(ie), &
                                        gamma1(ie),gamma2(ie), &
                                        delta1(ie),delta2(ie), & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i), con_DG(5,i), 1.d-6, 1.01d0,1)

                                        
                        dg_els(nel_dg_loc)%x_pl(ip) = -1.d0                        
                        dg_els(nel_dg_loc)%y_pl(ip) = eta
                        dg_els(nel_dg_loc)%wx_pl(ip) = nodes_DG(3,i)
                        dg_els(nel_dg_loc)%wy_pl(ip) = nodes_DG(4,i)
                        
                        dg_els(nel_dg_loc)%omega_minus(ip,0) = con_DG(4,i) 
                        dg_els(nel_dg_loc)%omega_minus(ip,1) = con_DG(5,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,2) = con_DG(6,i)
                        dg_els(nel_dg_loc)%omega_minus(ip,3) = 0 
                         
                         
                        ! find the corresponding neigh. elem in faces matrix
                         
                         call GET_FACE_DG(faces, nel_dg_glo, con_DG(5,i), con_DG(6,i), ih)
                         
                         call MAKE_BILINEAR_MAP(area_nodes(2:9,ih), &
                                             c_alfa1, c_alfa2, c_beta1, c_beta2, & 
                                             c_gamma1, c_gamma2, c_delta1, c_delta2)
                         
                                                  
                         call NEWTON_RAPSON(nodes_DG(1,i), nodes_DG(2,i), &
                                        c_alfa1, c_alfa2, &
                                        c_beta1, c_beta2, & 
                                        c_gamma1, c_gamma2, &
                                        c_delta1, c_delta2, & 
                                        tt, csi, eta, nofinr, &
                                        con_DG(2,i),con_DG(5,i), 1.d-6, 1.01d0,1)   
                                        
                         select case(con_DG(6,i))    
                            case(1)
                              eta = -1.d0
                            case(2)
                              csi = 1.d0
                            case(3)
                              eta = 1.d0
                            case(4)
                              csi = -1.d0
                            case default
                              write(*,*) 'error in make_interface'
                            end select             

                         dg_els(nel_dg_loc)%x_mn(ip) =  csi
                         dg_els(nel_dg_loc)%y_mn(ip) =  eta


                        endif                        
                            i = i+1                 
                       
                  enddo
 
                   call MAKE_NORMAL(4,xs(ne1), xs(ne2), ys(ne1), ys(ne2), normal_x, normal_y)

                   dg_els(nel_dg_loc)%nx = normal_x
                   dg_els(nel_dg_loc)%ny = normal_y

               endif   
               
                         
            endif

         enddo
      enddo
      
      
      deallocate(con_DG, nodes_DG)




!   Finding/ordering neigh. elements

     do it = 1, nel_dg_loc
            allocate(copia(max_quad_points,0:3))    
            copia = dg_els(it)%omega_minus
            
            call GET_NEIGHBOUR_ELEM(copia, dg_els(it)%quad_rule, nofne_el, max_quad_points)
            
            dg_els(it)%nofne = nofne_el                
            dg_els(it)%omega_minus(:,3) = copia(:,3)    

            deallocate(copia)
     enddo
    
    
!CHECK IF ALL DG EL HAVE A NEIGHBOUR   
     do it = 1, nel_dg_loc
        if(dg_els(it)%nofne == 0) then 
          write(*,*) 'ATTENTION : element ', dg_els(it)%ind_el, ' has 0 neighbouring elements'
        endif   
     enddo
    
     
     do it = 1, nel_dg_loc
         
        ic = 1
        do while(ic .le. dg_els(it)%nofne)
            do ip = 1, (dg_els(it)%quad_rule)  
               if(dg_els(it)%omega_minus(ip,3) .eq. ic) then
                  dg_els(it)%conf(ic,0) = dg_els(it)%omega_minus(ip,0)
                  dg_els(it)%conf(ic,1) = dg_els(it)%omega_minus(ip,1)
                  dg_els(it)%conf(ic,2) = dg_els(it)%omega_minus(ip,2)
               endif
            enddo
            ic = ic + 1
        enddo
     enddo

!*************************************************************************************************************
!                                   JUMP FOR DG INTERFACES
!*************************************************************************************************************        

    do ie = 1, nel_dg_loc
         nnz_p = 0
         nnz_m = 0   
         el_new(ie)%nnz_col = 0  
         
         if(test .eq. 1) then
              el_new(ie)%nnz_col_only_uv = 0; nnz_p_only_uv = 0; nnz_m_only_uv = 0   
         endif
   
         
         ielem = dg_els(ie)%ind_el
         iface = dg_els(ie)%face_el
         nn = dg_els(ie)%spct_deg + 1
         im = dg_els(ie)%mat
                  
         c11p = prop_mat(im,2) + 2*prop_mat(im,3); 
         c55p = prop_mat(im,3);
         c15p = 0;
         c35p = 0;

         if (im .eq. 1) then
            c33p = c11p  
            c13p = prop_mat(im,2) 
         else
            c33p = c11p * 6.20/16.50;
            c13p = prop_mat(im,2) * 5/16.50;
         endif                  
                  
                  
                  
         el_new(ie)%ind = ielem
         el_new(ie)%face = iface
         el_new(ie)%deg = nn   

         el_new(ie)%num_of_ne = dg_els(ie)%nofne

         call GET_FACE_DG(faces, nel_dg_loc, ielem, iface, ic1)
         
         allocate(el_new(ie)%matP(2*(nn**2),2*(nn**2)));  el_new(ie)%matP = 0.d0
         allocate(el_new(ie)%matM(dg_els(ie)%nofne))
         !--------------------------------------------------------------------------------------------
         if (test .eq. 1) then       
               allocate(el_new(ie)%matP_only_uv(2*(nn**2),2*(nn**2)));  el_new(ie)%matP_only_uv = 0.d0
               allocate(el_new(ie)%matM_only_uv(dg_els(ie)%nofne))
         endif      
         !--------------------------------------------------------------------------------------------

    
         do ic = 1, dg_els(ie)%nofne                   

            imne = dg_els(ie)%conf(ic,0)              
            iene = dg_els(ie)%conf(ic,1)
            ifacene = dg_els(ie)%conf(ic,2)
            
            mm = 2
            
            c11m = prop_mat(imne,2) + 2*prop_mat(imne,3); 
            c55m = prop_mat(imne,3);
            c15m = 0;
            c35m = 0;

            if (imne .eq. 1) then
               c33m = c11m  
               c13m = prop_mat(imne,2) 
            else
               c33m = c11m * 6.20/16.50;
               c13m = prop_mat(imne,2) * 5/16.50;
            endif

            do i = 1, nm 
              if(tag_mat(i) .eq. imne ) then
                   mm = sd(i) +1
                   
                   lambda = 2.d0*prop_mat(im,2)*prop_mat(i,2)/(prop_mat(im,2) + prop_mat(i,2))
                   mu = 2.d0*prop_mat(im,3)*prop_mat(i,3)/(prop_mat(im,3) + prop_mat(i,3))  
                   c11 = lambda + 2*mu;
                   c33 = c11       !*6.20/16.50;
                   c55 = mu;
                   c13 = lambda   !*5/16.50;
                   c15 = 0;
                   c35 = 0;                   
                   
                   !c11 = 2.d0*c11p*c11m/(c11p+c11m)
                   !c33 = c11
                   !c55 = 2.d0*c55p*c55m/(c55p+c55m) 
                   !c13 = 2.d0*c13p*c13m/(c13p+c13m) 
                   !c15 = 0.d0;
                   !c35 = 0.d0;
                                                      
              endif
            enddo   
            
            el_new(ie)%el_conf(ic,0) = imne           
            el_new(ie)%el_conf(ic,1) = iene
            el_new(ie)%el_conf(ic,2) = ifacene
                
            call GET_FACE_DG(faces, nel_dg_loc, iene, ifacene, ic2)
            
            allocate(JP(2*(nn**2),2*(nn**2)),el_new(ie)%matM(ic)%MJUMP(2*(nn**2),2*(mm**2)),JM(2*(nn**2),2*(mm**2)))
            !---------------------------------------------------------------------------------------------------
            if(test .eq. 1) then 
              allocate(JP_only_uv(2*(nn**2),2*(nn**2)),&
                       el_new(ie)%matM(ic)%MJUMP_only_uv(2*(nn**2),2*(mm**2)),JM_only_uv(2*(nn**2),2*(mm**2)))           
            endif 
            !---------------------------------------------------------------------------------------------------

            
            pen_h = min(area_nodes(1,ic1), area_nodes(1,ic2))                      
            pen_p = max(nn-1,mm-1)                     

            pen = penalty_c * (lambda + 2.d0*mu) * pen_p**2.d0 / pen_h
                       
!            cp_a = 0.5d0*(lambda+2.d0*mu)*dg_els(ie)%nx
!            cp_b = 0.5d0*lambda*dg_els(ie)%nx
!            cp_c = 0.5d0*mu*dg_els(ie)%ny
!            cp_e = 0.5d0*mu*dg_els(ie)%nx
!            cp_f = 0.5d0*(lambda+2.d0*mu)*dg_els(ie)%ny
!            cp_g = 0.5d0*lambda*dg_els(ie)%ny

            cp_a = 0.5d0*c11*dg_els(ie)%nx + 0.5d0*c15*dg_els(ie)%ny  
            cp_b = 0.5d0*c13*dg_els(ie)%nx + 0.5d0*c35*dg_els(ie)%ny
            cp_c = 0.5d0*c15*dg_els(ie)%nx + 0.5d0*c55*dg_els(ie)%ny
            cp_e = 0.5d0*c55*dg_els(ie)%nx + 0.5d0*c35*dg_els(ie)%ny
            cp_f = 0.5d0*c35*dg_els(ie)%nx + 0.5d0*c33*dg_els(ie)%ny
            cp_g = 0.5d0*c15*dg_els(ie)%nx + 0.5d0*c13*dg_els(ie)%ny



            call MAKE_BILINEAR_MAP(area_nodes(2:9,ic2), &
                                    c_alfa1, c_alfa2, &  
                                    c_beta1, c_beta2, &
                                    c_gamma1, c_gamma2, &
                                    c_delta1, c_delta2)



            call MAKE_LOC_MATRIX_DG(dg_els(ie)%x_pl, dg_els(ie)%y_pl, &
                       dg_els(ie)%wx_pl, dg_els(ie)%wy_pl,&
                       dg_els(ie)%x_mn, dg_els(ie)%y_mn, &
                       dg_els(ie)%quad_rule, nn, mm, &
                       dg_els(ie)%omega_minus(1:dg_els(ie)%quad_rule,0:3), &
                       alfa1(ielem),alfa2(ielem),&
                       beta1(ielem),beta2(ielem),&
                       gamma1(ielem),gamma2(ielem),&
                       delta1(ielem),delta2(ielem),&
                       iene, c_alfa1, c_alfa2,&
                       c_beta1,c_beta2, &
                       c_gamma1,c_gamma2,&
                       c_delta1,c_delta2,&
                       cp_a,cp_b,cp_c,cp_e,cp_f,cp_g, &
                       pen, dg_cnst, JP, JM, pen_h, test,&
                       JP_only_uv, JM_only_uv)

                       el_new(ie)%matP = el_new(ie)%matP + JP
                       el_new(ie)%matM(ic)%MJUMP = JM

                       !--------------------------------------------------------------------
                       if(test .eq. 1) then
                           el_new(ie)%matP_only_uv = el_new(ie)%matP_only_uv + JP_only_uv
                           el_new(ie)%matM(ic)%MJUMP_only_uv = JM_only_uv
                       endif       
                       !--------------------------------------------------------------------

                        do i = 1, 2*nn**2
                           do j = 1, 2*mm**2
                                   if(el_new(ie)%matM(ic)%MJUMP(i,j) .ne. 0.d0) nnz_m = nnz_m + 1
                                !------------------------------------------------------------------------------
                                   if(test .eq. 1 ) then
                                     if ( el_new(ie)%matM(ic)%MJUMP_only_uv(i,j) .ne. 0.d0) &
                                      nnz_m_only_uv = nnz_m_only_uv + 1
                                   endif   
                                !------------------------------------------------------------------------------
                           enddo
                        enddo       
                        
                        el_new(ie)%nnz_col = el_new(ie)%nnz_col + 2*mm**2 

                        !--------------------------------------------------------------------
                        if(test .eq. 1) then
                           el_new(ie)%nnz_col_only_uv = el_new(ie)%nnz_col_only_uv + 2*mm**2
                           deallocate(JM_only_uv,JP_only_uv)
                        endif
                        !--------------------------------------------------------------------

                                                   
                        deallocate(JM,JP)
        enddo


        do i = 1, 2*nn**2
           do j = 1, 2*nn**2
              if(el_new(ie)%matP(i,j) .ne. 0.d0) nnz_p = nnz_p + 1
           enddo
        enddo       
                    
        el_new(ie)%nnz_minus = nnz_m;  el_new(ie)%nnz_plus = nnz_p
        

        !--------------------------------------------------------------------------------------------            
        if(test .eq. 1) then
           do i = 1, 2*nn**2
              do j = 1, 2*nn**2
                 if(el_new(ie)%matP_only_uv(i,j) .ne. 0.d0) nnz_p_only_uv = nnz_p_only_uv + 1
              enddo
           enddo       
           el_new(ie)%nnz_minus_only_uv = nnz_m_only_uv;  el_new(ie)%nnz_plus_only_uv = nnz_p_only_uv
        endif                   
        !---------------------------------------------------------------------------------------------


!
! STORING MATRIX IN A SPARSE FORMAT
!

         nn = el_new(ie)%deg 
         allocate(el_new(ie)%IPlus(0:2*nn**2), el_new(ie)%IMin(0:2*nn**2))
         allocate(el_new(ie)%JPlus(el_new(ie)%nnz_plus),el_new(ie)%matPlus(el_new(ie)%nnz_plus))
         allocate(el_new(ie)%JMin(el_new(ie)%nnz_minus),el_new(ie)%matMin(el_new(ie)%nnz_minus))
         allocate(J4S(el_new(ie)%nnz_minus),M4S(el_new(ie)%nnz_minus))
         allocate(I4S(el_new(ie)%nnz_plus))

         k = 1
         do i = 1, 2*nn**2
            do j = 1, 2*nn**2
               if( el_new(ie)%matP(i,j) .ne. 0.d0 ) then
                  I4S(k) = i
                  el_new(ie)%JPlus(k) = j
                  el_new(ie)%matPlus(k) =  el_new(ie)%matP(i,j)
                  k = k + 1
                endif
             enddo
         enddo        

         deallocate(el_new(ie)%matP)

         el_new(ie)%IPlus= 0
         do i = 1, el_new(ie)%nnz_plus
            el_new(ie)%IPlus(I4S(i)) = el_new(ie)%IPlus(I4S(i)) + 1
         enddo
         do i = 1, 2*nn**2
            el_new(ie)%IPlus(i) = el_new(ie)%IPlus(i) + el_new(ie)%IPlus(i-1)
         enddo

         deallocate(I4S)
         allocate(I4S(el_new(ie)%nnz_minus))

         k = 1
         ishift = 0
         jshift = 0
         
         do ic = 1, el_new(ie)%num_of_ne

            mm = 2
            do i = 1, nm 
              if(tag_mat(i) .eq. el_new(ie)%el_conf(ic,0) ) then
                   mm = sd(i) +1
              endif
            enddo   
            
          
            do i = 1, 2*nn**2
               do j = 1, 2*mm**2
                  if( el_new(ie)%matM(ic)%MJUMP(i,j) .ne. 0.d0 ) then
                     I4S(k) = i 
                     J4S(k) = j + jshift
                     M4S(k) = el_new(ie)%matM(ic)%MJUMP(i,j)
                     
                     k = k + 1
                   endif

                enddo
            enddo        
            

            jshift = jshift + 2*mm**2

            deallocate(el_new(ie)%matM(ic)%MJUMP)
            
         
         enddo

         k = 1
         do i = 1, 2*nn**2
            do j = 1, el_new(ie)%nnz_minus
              if(I4S(j) .eq. i) then          
                 el_new(ie)%JMin(k) = J4S(j) 
                 el_new(ie)%matMin(k) = M4S(j)
                 k = k + 1
               endif
             enddo    
         enddo

           
         deallocate(J4S, M4S)  

         el_new(ie)%IMin = 0
         do i = 1, el_new(ie)%nnz_minus
            el_new(ie)%IMin(I4S(i)) = el_new(ie)%IMin(I4S(i)) + 1
         enddo
         
         do i = 1, 2*nn**2
            el_new(ie)%IMin(i) = el_new(ie)%IMin(i) + el_new(ie)%IMin(i-1)
         enddo

         deallocate(I4S)
                    
         !-----------------------------------------------------------------------------------------
         if(test .eq. 1) then  

           nn = el_new(ie)%deg 
           allocate(el_new(ie)%IPlus_only_uv(0:2*nn**2),el_new(ie)%IMin_only_uv(0:2*nn**2))
           allocate(el_new(ie)%JPlus_only_uv(el_new(ie)%nnz_plus_only_uv))
           allocate(el_new(ie)%matPlus_only_uv(el_new(ie)%nnz_plus_only_uv))
           allocate(el_new(ie)%JMin_only_uv(el_new(ie)%nnz_minus_only_uv))
           allocate(el_new(ie)%matMin_only_uv(el_new(ie)%nnz_minus_only_uv))
           allocate(J4S(el_new(ie)%nnz_minus_only_uv),M4S(el_new(ie)%nnz_minus_only_uv))
           allocate(I4S(el_new(ie)%nnz_plus_only_uv))

           k = 1
           do i = 1, 2*nn**2
              do j = 1, 2*nn**2
                 if( el_new(ie)%matP_only_uv(i,j) .ne. 0.d0 ) then
                    I4S(k) = i
                    el_new(ie)%JPlus_only_uv(k) = j
                    el_new(ie)%matPlus_only_uv(k) =  el_new(ie)%matP_only_uv(i,j)
                    k = k + 1
                 endif
               enddo
           enddo        

           deallocate(el_new(ie)%matP_only_uv)

           el_new(ie)%IPlus_only_uv= 0
           do i = 1, el_new(ie)%nnz_plus_only_uv
              el_new(ie)%IPlus_only_uv(I4S(i)) = el_new(ie)%IPlus_only_uv(I4S(i)) + 1
           enddo
           do i = 1, 2*nn**2
              el_new(ie)%IPlus_only_uv(i) = el_new(ie)%IPlus_only_uv(i) + el_new(ie)%IPlus_only_uv(i-1)
           enddo

           deallocate(I4S)
           allocate(I4S(el_new(ie)%nnz_minus_only_uv))

           k = 1
           ishift = 0
           jshift = 0
         
           do ic = 1, el_new(ie)%num_of_ne

              mm = 2
              do i = 1, nm 
                if(tag_mat(i) .eq. el_new(ie)%el_conf(ic,0) ) then
                     mm = sd(i) +1
                endif
              enddo   
            
          
              do i = 1, 2*nn**2
                 do j = 1, 2*mm**2
                    if( el_new(ie)%matM(ic)%MJUMP_only_uv(i,j) .ne. 0.d0 ) then
                       I4S(k) = i 
                       J4S(k) = j + jshift
                       M4S(k) = el_new(ie)%matM(ic)%MJUMP_only_uv(i,j)
                     
                       k = k + 1
                     endif
                 enddo
               enddo        
   
               jshift = jshift + 2*mm**2

               deallocate(el_new(ie)%matM(ic)%MJUMP_only_uv)
           enddo

           k = 1
           do i = 1, 2*nn**2
              do j = 1, el_new(ie)%nnz_minus_only_uv
                if(I4S(j) .eq. i) then          
                   el_new(ie)%JMin_only_uv(k) = J4S(j) 
                   el_new(ie)%matMin_only_uv(k) = M4S(j)
                   k = k + 1
                endif
              enddo    
           enddo

           deallocate(J4S, M4S)  

           el_new(ie)%IMin_only_uv = 0
           do i = 1, el_new(ie)%nnz_minus_only_uv
              el_new(ie)%IMin_only_uv(I4S(i)) = el_new(ie)%IMin_only_uv(I4S(i)) + 1
           enddo
         
           do i = 1, 2*nn**2
              el_new(ie)%IMin_only_uv(i) = el_new(ie)%IMin_only_uv(i) + el_new(ie)%IMin_only_uv(i-1)
           enddo

           deallocate(I4S)

 
          endif
          !-----------------------------------------------------------------------------------------



      enddo




     deallocate(dg_els)
         


    return

    end subroutine MAKE_DG_INTERFACE


