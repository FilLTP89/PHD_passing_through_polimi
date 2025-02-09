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


!> @brief SPEED (SPectral Elements in Elastodynamics with discontinuous Galerkin) 
!! is an open-source code for the simulation of seismic wave propagation in 
!! three-dimensional complex media. SPEED is jointly developed by MOX (The Laboratory for Modeling and Scientific 
!! Computing, Department of Mathematics) and DICA (Department of Civil and Environmental Engineering)
!! at Politecnico di Milano.
!> @see Website http://mox.polimi.it/speed/SPEED/Home.html
!! @author Ilario Mazzieri
!> @date April, 2014
!> @version 1.0


! Here starts the code SPEED2D

      program SPEED2D

      use speed_par_dg
      
      implicit none

      logical :: filefound
      
!     INPUT FILES
      character*70 :: head_file,grid_file,mat_file,out_file
      
!   SYSTEM CLOCK
      integer*4 :: COUNTCLOCK(1:1), COUNTRATE, COUNTMAX
      integer*4 :: START_TIME(1:8),END_TIME(1:8), OMP_GET_NUM_PROCS    
      integer*4 :: start, finish    
      integer*4, dimension(3)  :: clock
      
!     OPTIONS OUTPUT      
      integer*4, dimension (6) :: opt_out_var
      
!     TIME VARIABLES
      real*8 :: time_in_seconds, deltat, xtime, &
                deltat_cfl, fmax, fpeak, ndt_mon
      
!     MODEL VARIABLES
      real*8, dimension (:), allocatable :: xx_macro,yy_macro
      real*8, dimension (:), allocatable :: xx_spx,yy_spx
      integer*4 :: nnod_macro,nnod, nedge_abc, nelem_abc
      integer*4, dimension (:,:), allocatable :: con
      integer*4, dimension (:), allocatable :: con_spx
      integer*4 :: nelem,con_nnz
      integer*4, dimension (:,:), allocatable :: con_bc
      integer*4, dimension (:), allocatable :: con_spx_bc, i4count
      integer*4, dimension (:), allocatable :: iedge_abc, ielem_abc
      integer*4 ::nedge,con_nnz_bc
      integer*4, dimension (:), allocatable :: Ebw,Ebin,Nbw,Nbin
      integer*4 :: Ennz,Nnnz, iedge,ied1,ied2,iel1,iel2,iel3,iel4
      real*8, dimension (:), allocatable :: alfa1,beta1,gamma1,delta1
      real*8, dimension (:), allocatable :: alfa2,beta2,gamma2,delta2
      
!     MECHANICAL VARIABLES
      integer*4 :: nmat
      integer*4, dimension (:), allocatable :: sdeg_mat
      integer*4, dimension(:), allocatable :: tag_mat
      real*8, dimension (:,:), allocatable :: prop_mat
      real*8, dimension (:), allocatable :: u0,v0,Mel,Cel,KCel
      real*8, dimension (:,:), allocatable :: Fel
      real*8, dimension (:,:), allocatable :: val_dirX_el,val_dirY_el
      real*8, dimension (:,:), allocatable :: val_neuX_el,val_neuY_el
      real*8, dimension (:,:), allocatable :: val_poiX_el,val_poiY_el
      real*8, dimension (:,:), allocatable :: val_plaX_el,val_plaY_el
      real*8, dimension (:,:), allocatable :: val_sism_el
      integer*4, dimension (:), allocatable :: fun_dirX_el,fun_neuX_el
      integer*4, dimension (:), allocatable :: fun_dirY_el,fun_neuY_el
      integer*4, dimension (:), allocatable :: fun_poiX_el,fun_poiY_el
      integer*4, dimension (:), allocatable :: fun_plaX_el,fun_plaY_el
      integer*4, dimension (:), allocatable :: fun_sism_el
      integer*4, dimension(:), allocatable :: tag_dirX_el,tag_neuX_el,tag_plaX_el
      integer*4, dimension(:), allocatable :: tag_dirY_el,tag_neuY_el,tag_plaY_el
      integer*4, dimension(:), allocatable :: tag_sism_el
      integer*4, dimension(:), allocatable :: tag_abc_el
      integer*4 :: nload_dirX_el,nload_dirY_el
      integer*4 :: nload_neuX_el,nload_neuY_el
      integer*4 :: nload_poiX_el,nload_poiY_el
      integer*4 :: nload_plaX_el,nload_plaY_el
      integer*4 :: nload_sism_el
      integer*4 :: nload_abc_el
      integer*4, dimension (:), allocatable :: fun_test
      integer*4, dimension (:), allocatable :: tag_func
      integer*4, dimension (:), allocatable :: func_type
      integer*4, dimension (:), allocatable :: func_indx
      real*8, dimension (:), allocatable :: func_data
      integer*4 :: nfunc,nfunc_data
      real*8, dimension (:), allocatable :: tsnap
      real*8, dimension (:), allocatable :: x_monitor,y_monitor
      integer*4, dimension (:),   allocatable :: itersnap
      integer*4, dimension (:),   allocatable :: n_monitor   
      integer*4 :: ns,nn,nn2,im,ie,i,j,in,ic,id,nts,nsnaps,nmonitors,trash
      real*8 :: eps
      
!     SEISMIC MOMENT VARIABLE
      real*8, dimension(:,:), allocatable :: facsmom
      integer*4, dimension(:), allocatable :: num_node_sism
      integer*4, dimension(:,:), allocatable :: sour_node_sism  
      real*8, dimension(:,:), allocatable :: dist_sour_node_sism
      integer*4, dimension(:,:), allocatable :: check_node_sism
      real*8, dimension(:,:), allocatable :: check_dist_node_sism
      integer*4 :: max_num_node_sism,length_check_node_sism
      integer*4 :: conta
 
!   DAMPING MATRIX VARIABLES
      integer*4 :: make_damping_yes_or_not 
      
!   MLST VARIABLES
      real*8 :: depth_search_mon_lst
      integer*4 ::num_lst, file_mon_lst      
      real*8, dimension(:), allocatable :: dist_monitor_lst, x_monitor_lst, y_monitor_lst
      character*70 :: file_LS, file_MLST
      
!   TIME APPROXIMATION
     integer*4 :: test, n_test, time_degree
     real*8 :: pi  
      
!   SPARSE MATRIX VARIABLES
    integer*4, parameter :: max_nodes    = 10000
    integer*4, dimension(:,:), allocatable :: STIFF_PATTERN, ABC_PATTERN     
    integer*4, dimension(:), allocatable :: I_STIFF, J_STIFF, I_ABC, J_ABC, J_MASS, I_MASS
    integer*4, dimension(:), allocatable :: NDEGR,IW, I_SUM, J_SUM, IN_SUM, JN_SUM,&
                                            IC_SUM, JC_SUM, ID_SUM, JD_SUM, IE_SUM, JE_SUM, &
                                            IN_TOT, JN_TOT, IK_TOT, JK_TOT, IK_MORSE, JK_MORSE, &
                                            IN_MORSE, JN_MORSE, I_FULL, J_FULL, IFULL_MORSE, JFULL_MORSE
                                             
    real*8, dimension(:), allocatable :: M_STIFF, M_ABC_U, M_ABC_V, C_MASS, D_MASS, M_MASS, C_SUM, &
                                         D_SUM, E_SUM, N_TOT, K_TOT, K_MORSE, N_MORSE, M_FULL, MFULL_MORSE
                                         
    integer*4 :: length, length_abc, NNZ_AB, NNZ_K, NNZ_N, ierr, NNZ_N_MORSE, NNZ_K_MORSE, NNZ_FULL, NNZ_FULL_MORSE
    
    
!   DG VARIABLES
    character*70 :: file_face
    integer*4 :: nload_dg_el, nelem_dg, nnode_dg, nnz_dg_total, nnz_dg, &
                 nnz_dg_total_only_uv, nnz_dg_only_uv
                
    integer*4, dimension(:), allocatable ::  tag_dg_el, tag_dg_yn
    integer*4, dimension (:,:), allocatable :: faces
    real*8 :: dg_const, dg_pen
    real*8, dimension (:,:), allocatable :: area_nodes

!   SPARSE MATRIX DG VARIABLES    
    integer*4, dimension(:), allocatable :: IDG_TOTAL, JDG_TOTAL, IDG, JDG, IDG_MORSE, JDG_MORSE, &
                                            IDG_SUM, JDG_SUM, IDG_only_uv, JDG_only_uv
    real*8, dimension(:), allocatable :: MDG_TOTAL, MDG, MDG_MORSE, MDG_SUM, MDG_only_uv
    

!*****************************************************************************************      
!  START
!*****************************************************************************************      
      call system_clock(COUNT=start,COUNT_RATE=clock(2))
   
      write(*,'(A)')''
      write(*,'(A)')'*******************************************************'
      write(*,'(A)')'*                                                     *'
      write(*,'(A)')'*                        SPEED                        *'
      write(*,'(A)')'*          SPectral Elements in Elastodynamics        *'
      write(*,'(A)')'*              with Discontinuous Galerkin            *'
      write(*,'(A)')'*                                                     *'
      write(*,'(A)')'*            PoliMi, 2012, All Rights Reserved        *'
      write(*,'(A)')'*                                                     *'
      write(*,'(A)')'*******************************************************'
      write(*,'(A)')'*                                                     *'
      write(*,'(A)')'*                  2D - DG Space-Time SEM             *'  
      write(*,'(A)')'*                      Serial version                 *'
      write(*,'(A)')'*                                                     *'
      write(*,'(A)')'*******************************************************'


!*****************************************************************************************      
!  READ HEADER FILE
!*****************************************************************************************      
      
      head_file = 'SPEED.input'
      
      write(*,'(A)') 
      write(*,'(A)')'------------------Reading Header File------------------'
      write(*,'(A,A36)') 'Header File: ',head_file

      inquire(file=head_file,exist=filefound); if(filefound .eqv. .FALSE.) stop

      opt_out_var = 0   !do not write output files 

      
      call READ_DIME_HEADER(head_file,nsnaps)
          
      if (nsnaps.gt.0) allocate(tsnap(nsnaps),itersnap(nsnaps));
      
      time_degree = 0;
      call READ_HEADER(head_file, grid_file, mat_file, out_file,&
                       deltat, xtime, opt_out_var, &
                       nsnaps, tsnap, ndt_mon, depth_search_mon_lst, num_lst,&        
                       file_mon_lst,time_degree, test, dg_const, dg_pen)     
      
!*****************************************************************************************      
!  READ MATE FILE
!*****************************************************************************************      

      write(*,'(A)')'Read.'
      
      mat_file = mat_file(1:len_trim(mat_file)) // '.mate'
      
      write(*,'(A)')    
      write(*,'(A,A20)')'-----------------Reading Material File-----------------'
      write(*,'(A,A20)')'Material File : ',mat_file
      
      inquire(file=mat_file,exist=filefound); if(filefound .eqv. .FALSE.) stop

      
      call READ_DIME_MAT_EL(mat_file,nmat, &
                            nload_dirX_el,nload_dirY_el, &
                            nload_neuX_el,nload_neuY_el, &
                            nload_poiX_el,nload_poiY_el, &
                            nload_plaX_el,nload_plaY_el, &
                            nload_sism_el, & 
                            nload_abc_el, &
                            nfunc,nfunc_data,n_test,&
                            nload_dg_el)
                            
                                  
      write(*,'(A,I8)')'Materials      : ',nmat
      write(*,'(A,I8)')'Dichlet X B.C. : ',nload_dirX_el
      write(*,'(A,I8)')'Dichlet Y B.C. : ',nload_dirY_el
      write(*,'(A,I8)')'Neumann X B.C. : ',nload_neuX_el
      write(*,'(A,I8)')'Neumann Y B.C. : ',nload_neuY_el
      write(*,'(A,I8)')'DG Interfaces  : ',nload_dg_el
      write(*,'(A,I8)')'Absorbing B.C. : ',nload_abc_el
      write(*,'(A,I8)')'Point Loads X  : ',nload_poiX_el
      write(*,'(A,I8)')'Point Loads Y  : ',nload_poiY_el
      write(*,'(A,I8)')'Plane Loads X  : ',nload_plaX_el
      write(*,'(A,I8)')'Plane Loads Y  : ',nload_plaY_el
      write(*,'(A,I8)')'Moment Loads  :  ',nload_sism_el
      if (nmat.le.0) then
             write(*,*)'Error ! nmat = 0';   stop
      endif
      
      allocate (sdeg_mat(nmat), prop_mat(nmat,4), tag_mat(nmat))

      if (nload_dirX_el.gt.0) &
         allocate (val_dirX_el(nload_dirX_el,2),fun_dirX_el(nload_dirX_el),tag_dirX_el(nload_dirX_el))
      if (nload_dirY_el.gt.0) & 
         allocate (val_dirY_el(nload_dirY_el,2),fun_dirY_el(nload_dirY_el),tag_dirY_el(nload_dirY_el))
      
      if (nload_neuX_el.gt.0) &
         allocate (val_neuX_el(nload_neuX_el,2),fun_neuX_el(nload_neuX_el),tag_neuX_el(nload_neuX_el))     
      if (nload_neuY_el.gt.0) &
         allocate (val_neuY_el(nload_neuY_el,2),fun_neuY_el(nload_neuY_el),tag_neuY_el(nload_neuY_el))
      
      if (nload_poiX_el.gt.0) allocate (val_poiX_el(nload_poiX_el,3), fun_poiX_el(nload_poiX_el))
      if (nload_poiY_el.gt.0) allocate (val_poiY_el(nload_poiY_el,3), fun_poiY_el(nload_poiY_el))

      if (nload_plaX_el.gt.0) &
         allocate (val_plaX_el(nload_plaX_el,1),fun_plaX_el(nload_plaX_el),tag_plaX_el(nload_plaX_el))
      if (nload_plaY_el.gt.0) &
         allocate (val_plaY_el(nload_plaY_el,1),fun_plaY_el(nload_plaY_el),tag_plaY_el(nload_plaY_el))


      if (nload_sism_el.gt.0) &
         allocate (val_sism_el(nload_sism_el,12),fun_sism_el(nload_sism_el),tag_sism_el(nload_sism_el))  

      if (nload_abc_el.gt.0) allocate (tag_abc_el(nload_abc_el))
      if (nload_dg_el.gt.0) allocate (tag_dg_el(nload_dg_el), tag_dg_yn(nload_dg_el))      

      if (nfunc.gt.0) &
         allocate (tag_func(nfunc),func_type(nfunc),func_indx(nfunc +1),func_data(nfunc_data))
         
      if (n_test.gt.0) allocate (fun_test(n_test))


      call READ_MATERIAL_EL(mat_file,nmat,prop_mat,sdeg_mat,tag_mat,&
                nload_dirX_el,val_dirX_el,fun_dirX_el,tag_dirX_el, &
                nload_dirY_el,val_dirY_el,fun_dirY_el,tag_dirY_el, &
                nload_neuX_el,val_neuX_el,fun_neuX_el,tag_neuX_el, &
                nload_neuY_el,val_neuY_el,fun_neuY_el,tag_neuY_el, &
                nload_poiX_el,val_poiX_el,fun_poiX_el, &
                nload_poiY_el,val_poiY_el,fun_poiY_el, &
                nload_plaX_el,val_plaX_el,fun_plaX_el,tag_plaX_el, &
                nload_plaY_el,val_plaY_el,fun_plaY_el,tag_plaY_el, &
	        nload_sism_el,val_sism_el,fun_sism_el,tag_sism_el, &
                nload_abc_el,tag_abc_el, &
                nfunc,func_type,func_indx,func_data,tag_func, &
                fmax, n_test, fun_test, &
                nload_dg_el,tag_dg_el,tag_dg_yn)
      

      write(*,'(A)')'Read.'      
            
      do im = 1,nmat
         write(*,'(A,I8)')    'MATERIAL : ',tag_mat(im)
         write(*,'(A,I8)')    'DEGREE   : ',sdeg_mat(im)
         write(*,'(A,E12.4)') 'rho      : ',prop_mat(im,1)
         write(*,'(A,E12.4)') 'Vp       : ',((prop_mat(im,2) + 2*prop_mat(im,3))/prop_mat(im,1))**0.5
         write(*,'(A,E12.4)') 'Vs       : ',(prop_mat(im,3)/prop_mat(im,1))**0.5
         write(*,'(A,E12.4)') 'gamma    : ',prop_mat(im,4)
         write(*,*)
      enddo                                                                         

!*****************************************************************************************      
!  READ GRID FILE
!*****************************************************************************************      
      
      grid_file = grid_file(1:len_trim(grid_file)) // '.mesh'    
      write(*,'(A)') '-------------------Reading Grid File-------------------'
      write(*,'(A,A20)') 'Grid File : ',grid_file
      
      inquire(file=grid_file,exist=filefound); if(filefound .eqv. .FALSE.) stop
      

      call READ_DIME_GRID_EL(grid_file,nmat,tag_mat,&
                     nload_dirX_el,tag_dirX_el,nload_dirY_el,tag_dirY_el,&
                     nload_neuX_el,tag_neuX_el,nload_neuY_el,tag_neuY_el,&
                     nload_abc_el,tag_abc_el,&
                     nload_dg_el,tag_dg_el, &
                     nnod_macro,nelem,nedge)
      
      write(*,'(A,I8)')'Nodes : ',nnod_macro
      write(*,'(A,I8)')'Elements : ',nelem
      write(*,'(A,I8)')'Edges : ',nedge
      
      if (nnod_macro.gt.0) then
         allocate (xx_macro(nnod_macro),yy_macro(nnod_macro))
      else
         write(*,*)'Error ! Vertex number = 0'; stop
      endif
      
      if (nelem.gt.0) then
         allocate (con(nelem,5))
      else
         write(*,*)'Error ! Element number = 0'; stop
      endif
      
      if (nedge.gt.0) allocate (con_bc(nedge,3))
      
      call READ_GRID_EL(grid_file,nmat,tag_mat,prop_mat,&
                        nload_dirX_el,tag_dirX_el,nload_dirY_el,tag_dirY_el,&
                        nload_neuX_el,tag_neuX_el,nload_neuY_el,tag_neuY_el,&
                        nload_abc_el,tag_abc_el,&
                        nload_dg_el,tag_dg_el,&
                        nnod_macro,xx_macro,yy_macro,nelem,con,nedge,con_bc)
      
      write(*,'(A)')'Read.'    
      write(*,'(A)')

!*****************************************************************************************      
!  MAKING SPECTRAL CONNECTIVITY
!*****************************************************************************************      

      write(*,'(A)') '-------------Making Spectral connectivities------------'
      
      allocate(Ebw(nnod_macro))    
      call MAKE_EBW_MACRO(nnod_macro,nelem,con,Ebw,Ennz)
      
      allocate(Ebin(0:Ennz))
      call MAKE_EBIN_MACRO(nnod_macro,nelem,con,Ebw,Ennz,Ebin)
      
      deallocate(Ebw)
      
      con_nnz = nelem +1
      do ie = 1,nelem
         do j = 1,nmat
            if (tag_mat(j).eq.con(ie,1)) nn = sdeg_mat(j) +1
         enddo
         con_nnz = con_nnz + nn*nn +1
      enddo
      
      allocate(con_spx(0:con_nnz))
      call MAKE_SPECTRAL_CONNECTIVITY(nelem,con,nmat,tag_mat,sdeg_mat,&
                                      Ennz,Ebin,con_nnz,con_spx,nnod)
      
      
      deallocate(Ebin)
      
     ! Dual connectivity for spectral nodes
       
      allocate(Ebw(nnod))
      call MAKE_EBW(nnod,con_nnz,con_spx,Ebw,Ennz)
      
      allocate(Ebin(0:Ennz))
      call MAKE_EBIN(nnod,con_nnz,con_spx,Ebw,Ennz,Ebin)
      
      deallocate(Ebw)
      
      allocate(xx_spx(nnod),yy_spx(nnod))
      allocate(alfa1(nelem),beta1(nelem),gamma1(nelem),delta1(nelem))
      allocate(alfa2(nelem),beta2(nelem),gamma2(nelem),delta2(nelem))
      
      write(*,'(A,I8)')'Spectral Nodes : ',nnod
      
      call MAKE_SPECTRAL_GRID(nnod_macro,xx_macro,yy_macro,con_nnz,con_spx,&
                              nmat,tag_mat,sdeg_mat,nelem,&
                              alfa1,beta1,gamma1,delta1,&
                              alfa2,beta2,gamma2,delta2,&
                              nnod,xx_spx,yy_spx)
      
!     Make the spectral connectivities for the boundary
      
      con_nnz_bc = 0
      
      if (nedge.gt.0) then
         con_nnz_bc = nedge +1
         do i = 1,nedge
            
            call GET_EDGE_ELEMENT(Ennz,Ebin,con_bc(i,2),con_bc(i,3),ie)

            do j = 1,nmat
               
               if (tag_mat(j).eq.con(ie,1)) nn = sdeg_mat(j) +1
            enddo
            con_nnz_bc = con_nnz_bc +nn +1
         enddo
         
         allocate(con_spx_bc(0:con_nnz_bc))
         
         call MAKE_SPECTRAL_BOUNDARY(con_nnz,con_spx,nedge,con_bc,&
                                     nmat,tag_mat,sdeg_mat,Ennz,Ebin,&
                                     con_nnz_bc,con_spx_bc)
      endif


      write(*,'(A)')'Made.'
      

!*****************************************************************************************      
!  MAKE MASS MATRIX
!*****************************************************************************************      
      
      write(*,'(A)')
      write(*,'(A)') '------------Building the ELASTIC matrices--------------'
      write(*,'(A)')
      write(*,'(A)') '--------------Building the mass matrix-----------------'
      
      allocate (Mel(2*nnod))
      call MAKE_MEL(nnod, con_nnz,con_spx,&
                    nmat,tag_mat,sdeg_mat,prop_mat,&
                    nelem,alfa1,beta1,gamma1,alfa2,beta2,gamma2,Mel)
                    
      write(*,'(A)') 'Mass matrix built'


!*****************************************************************************************      
!  MAKE DAMPING MATRIX
!*****************************************************************************************      

      !Check if there is any damping factor between materials characteristics    
      make_damping_yes_or_not = 0
      
      do im = 1,nmat
         if (abs(prop_mat(im,4)) .gt. 10e-10) make_damping_yes_or_not = 1
      enddo

      if (make_damping_yes_or_not.eq.1) then
      
         write(*,'(A)')
         write(*,'(A)') '-------------Building the damping matrix---------------'
     
         allocate (Cel(2*nnod),KCel(2*nnod))

         call MAKE_CEL_KCEL(nnod,con_nnz,con_spx,&
                            nmat,tag_mat,sdeg_mat,prop_mat,&
                            nelem,alfa1,beta1,gamma1,alfa2,beta2,gamma2,&
                            Cel,KCel)
                            
         write(*,'(A)') 'Damping matrix built'
  
      else
      
         write(*,'(A)')
         write(*,'(A)') 'Damping matrix... NOT BUILT!!!'
         write(*,'(A)') 'There are no materials with damping defined on'
      
      endif
      
!*****************************************************************************************      
!  MAKE THE LOAD MATRIX --- EXTERNAL LOADS --- SEISmIC MOMENT
!*****************************************************************************************      
      
      write(*,'(A)')
      write(*,'(A)') '--------------Building the laod matrix-----------------'


      ! Dimensioning vector 'num_node_sism'(nodes number generating each single fault)
      if (nload_sism_el.gt.0) then

         write(*,'(A)')
         write(*,'(A)') '---------------Make the seismic moment-----------------'

         allocate (num_node_sism(nload_sism_el))

         do i = 1,nload_sism_el
            if (((val_sism_el(i,1).eq.val_sism_el(i,3)).and.(val_sism_el(i,3).eq.val_sism_el(i,5))) &
               .and.((val_sism_el(i,1).eq.val_sism_el(i,3)).and.(val_sism_el(i,3).eq.val_sism_el(i,5))))  then
               
               num_node_sism(i)=1
            else  
               call DIME_SISM_NODES(val_sism_el(i,1),val_sism_el(i,2),val_sism_el(i,3),val_sism_el(i,4),&
                                    val_sism_el(i,5),val_sism_el(i,6),val_sism_el(i,7),val_sism_el(i,8),&
                                    nnod,xx_spx,yy_spx,num_node_sism(i))
            endif
         enddo

         !Checking the maximum number of fault nodes
         max_num_node_sism = num_node_sism(1)
         do i = 1,nload_sism_el
                if (num_node_sism(i).gt.max_num_node_sism) then
                        max_num_node_sism = num_node_sism(i)
                endif
         enddo
      
         allocate (sour_node_sism(max_num_node_sism,nload_sism_el))
         allocate (dist_sour_node_sism(max_num_node_sism,nload_sism_el))
      
         !Searching the node 'id' in the global numeration for each fault.
         !sour_node_sism = node id (global numeration) generating the fault 'i'
         do i = 1,nload_sism_el
            if (num_node_sism(i).eq.1) then
               
               call FIND_NEAREST_NODE(nnod,xx_spx,yy_spx,val_sism_el(i,1),val_sism_el(i,2),sour_node_sism(1,i))
               dist_sour_node_sism(1,i) = 0
                
            else 
               call READ_SISM_NODES(val_sism_el(i,1),val_sism_el(i,2),val_sism_el(i,3),val_sism_el(i,4),&
                                    val_sism_el(i,5),val_sism_el(i,6),val_sism_el(i,7),val_sism_el(i,8),&
                                    nnod,xx_spx,yy_spx,num_node_sism(i),sour_node_sism,i,&
                                    dist_sour_node_sism,nload_sism_el,&
                                    max_num_node_sism)
            endif
                
            if (i.eq.1) then
               write(*,'(A)')'Sesmic moment & fault'
               write(*,'(A)')
            endif
            if (num_node_sism(i).eq.1) then
               write(*,'(A,I6,A)')'Sism ',i,' is located on:'
               write(*,'(I6,2E14.5,I6)')(j,xx_spx(sour_node_sism(j,i)),&
                         yy_spx(sour_node_sism(j,i)),sour_node_sism(j,i),&
                         j=1,num_node_sism(i))
            else
               write(*,'(A,I6,A,I6,A)')'Fault ',i,' is generated by ',num_node_sism(i),' nodes'
               write(*,'(I6,2E14.5,I6)')(j,xx_spx(sour_node_sism(j,i)),&
                         yy_spx(sour_node_sism(j,i)),sour_node_sism(j,i),&
                        j=1,num_node_sism(i)) 
            endif
            write(*,'(A)')
         enddo

         write(*,'(A)')
         write(*,'(A)') 'Seismic moment built.'
      endif

      

      if (nfunc .le. 0) nfunc = 1
      if (nload_sism_el.gt.0) allocate (facsmom(nload_sism_el,3))

      write(*,'(A)')
      write(*,'(A)') '-----------------Make the load vector------------------'


      allocate (Fel(nfunc,2*nnod))
      
       call MAKE_FEL(nnod,xx_spx,yy_spx,con_nnz,con_spx,&
                    nmat,tag_mat,sdeg_mat,prop_mat,&
                    nelem,alfa1,beta1,gamma1,alfa2,beta2,gamma2,&
                    con_nnz_bc,con_spx_bc,&
                    nload_dirX_el,val_dirX_el,fun_dirX_el,tag_dirX_el,&
                    nload_dirY_el,val_dirY_el,fun_dirY_el,tag_dirY_el,&
                    nload_neuX_el,val_neuX_el,fun_neuX_el,tag_neuX_el,&
                    nload_neuY_el,val_neuY_el,fun_neuY_el,tag_neuY_el,&
                    nload_poiX_el,val_poiX_el,fun_poiX_el,&
                    nload_poiY_el,val_poiY_el,fun_poiY_el,&
                    nload_plaX_el,val_plaX_el,fun_plaX_el,tag_plaX_el,&
                    nload_plaY_el,val_plaY_el,fun_plaY_el,tag_plaY_el,&
                    nload_sism_el,val_sism_el,fun_sism_el,tag_sism_el,&
                    nfunc,tag_func,Fel,&
                    xx_macro,yy_macro,con,nelem,con_bc,nedge,&
                    num_node_sism,max_num_node_sism,&  
                    sour_node_sism,dist_sour_node_sism,&
                    length_check_node_sism,facsmom, test, n_test, fun_test)
                    
                    
      if (nload_sism_el.gt.0) then
         allocate (check_node_sism(length_check_node_sism,5)) 
         allocate (check_dist_node_sism(length_check_node_sism,1))

      
         call CHECK_SISM(con_nnz,con_spx,&
                         nmat,tag_mat,sdeg_mat,&   
                         nelem,&
                         nload_sism_el,&
                         num_node_sism,max_num_node_sism,&
                         sour_node_sism,dist_sour_node_sism,&
                         check_node_sism,check_dist_node_sism,&
                         length_check_node_sism,&
                         fun_sism_el,nfunc,tag_func,val_sism_el)

         deallocate (sour_node_sism)
         deallocate (dist_sour_node_sism)
      endif


      write(*,'(A)')'Load matrix built.'
            
      deallocate (Ebin)

      write(*,'(A)')
      write(*,'(A)') '--------------Building the time matrix-----------------'

!********************************************************************************************************
!     REWRITE MASS MATRIX & DUMPING MATRIX IN CRS SPARSE FORMAT
!********************************************************************************************************
      
      write(*,'(A)')
      write(*,'(A)') '------------Building the sparse mass matrix------------'
                                    
      allocate(I_MASS(0:2*nnod));     I_MASS = 0;
      do i = 1, 2*nnod
        I_MASS(i) = I_MASS(i-1) + 1;
      enddo
     
      allocate(J_MASS(2*nnod), M_MASS(2*nnod));   J_MASS = 0; M_MASS = 0.d0
      allocate(C_MASS(2*nnod), D_MASS(2*nnod));   C_MASS = 0.d0; D_MASS = 0.d0
      
      do i = 1, 2*nnod
         J_MASS(i) = i;
         M_MASS(i) = Mel(i);
         if (make_damping_yes_or_not .eq. 1) C_MASS(i) = Cel(i);
         if (make_damping_yes_or_not .eq. 1) D_MASS(i) = KCel(i);                
      enddo   
      
      write(*,'(A)') 'Done'

!********************************************************************************************************
!     BUILD THE STIFFNESS MATRIX  IN CRS SPARSE FORMAT
!********************************************************************************************************

      write(*,'(A)')     
      write(*,'(A)') '----------Building pattern 4 stiffness matrix----------'
      
      allocate(STIFF_PATTERN(2*nnod, max_nodes));    STIFF_PATTERN = 0;
      allocate(I_STIFF(0:2*nnod));                   I_STIFF = 0;
    
      write(*,*) 'call make pattern'
      call MAKE_PATTERN_STIFF_MATRIX(STIFF_PATTERN, nnod, max_nodes, nelem, nmat, sdeg_mat, &
                                     con_spx, con_nnz, I_STIFF, length)
      write(*,*) 'end call'
         
      allocate(J_STIFF(1:length),M_STIFF(1:length))
      J_STIFF = 0;     M_STIFF = 0.d0;

      j = 0
      do i = 1 , 2*nnod
         call COUNT_NNZ_EL(STIFF_PATTERN, 2*nnod, max_nodes, i,ic)
         J_STIFF(j+1 : j + ic) = STIFF_PATTERN(i,1:ic)
         j = j + ic
      enddo
    
      deallocate(STIFF_PATTERN)       
      write(*,'(A)') 'Done.'
      write(*,'(A)')
      write(*,'(A)') '-------------Building the stiffness matrix-------------'

      call MAKE_STIFF_MATRIX(nnod,length,I_STIFF,J_STIFF,M_STIFF, &
                             nelem, con_nnz, con_spx, nmat, tag_mat, prop_mat, sdeg_mat, &
                             alfa1, alfa2, beta1, beta2, gamma1, gamma2)

      write(*,'(A)') 'Done.'
            
!********************************************************************************************************
!     BUILD THE ABCs MATRIX IN CRS SPARSE FORMAT
!********************************************************************************************************

      nelem_abc = 0; nedge_abc= 0;
      
      if(nload_abc_el .ge. 1) then
      
         nedge_abc = 0; 
         if (con_nnz_bc.gt.0) then
             nedge = con_spx_bc(0) -1
             allocate(i4count(nedge)); i4count = 0

             call MAKE_ABC(nedge_abc, nedge, i4count,con_nnz_bc,con_spx_bc,&
                          con_nnz,con_spx, nload_abc_el,tag_abc_el)

             if (nedge_abc.gt.0) then
                 allocate(iedge_abc(nedge_abc))
                 do iedge = 1,nedge
                    if (i4count(iedge).ne.0) then
                        iedge_abc(i4count(iedge)) = iedge
                    endif
                 enddo
         
                 deallocate(i4count)
             endif    
         endif
         
         nelem_abc = nedge_abc

         if (nelem_abc.gt.0) then
            allocate(ielem_abc(nelem_abc))
         
            do i = 1,nedge_abc
               iedge = iedge_abc(i)
               ied1 = con_spx_bc(con_spx_bc(iedge -1) +1)
               ied2 = con_spx_bc(con_spx_bc(iedge) -1)
            
               do ie = 1, nelem
                  nn = con_spx_bc(iedge) - con_spx_bc(iedge -1) -1
                  iel1 = con_spx(con_spx(ie -1) +1)
                  iel2 = con_spx(con_spx(ie -1) +nn)
                  iel3 = con_spx(con_spx(ie -1) +nn*nn)
                  iel4 = con_spx(con_spx(ie -1) +nn*(nn -1) +1)
                  if (((ied1.eq.iel1).or.(ied1.eq.iel2).or. (ied1.eq.iel3).or.(ied1.eq.iel4)).and. &
                     ((ied2.eq.iel1).or.(ied2.eq.iel2).or. (ied2.eq.iel3).or.(ied2.eq.iel4))) then
                     ielem_abc(i) = ie
                  endif
               enddo
            enddo
         
            write(*,'(A)')
            write(*,'(A)') '----------Building pattern 4 abc conditions------------'

            allocate(ABC_PATTERN(2*nnod, max_nodes));    ABC_PATTERN = 0;
            allocate(I_ABC(0:2*nnod));                   I_ABC = 0;
    
            call MAKE_PATTERN_ABC_MATRIX(ABC_PATTERN, nnod, max_nodes, nelem_abc, ielem_abc, nmat, sdeg_mat, &
                                     con_spx, con_nnz, I_ABC, length_abc)
         
            allocate(J_ABC(1:length_abc),M_ABC_U(1:length_abc),M_ABC_V(1:length_abc))
            J_ABC = 0;     M_ABC_U = 0.d0;  M_ABC_V = 0.d0; 

            j = 0
            do i = 1 , 2*nnod
               call COUNT_NNZ_EL(ABC_PATTERN, 2*nnod, max_nodes, i,ic)
               J_ABC(j+1 : j + ic) = ABC_PATTERN(i,1:ic)
               j = j + ic
            enddo
      
            deallocate(ABC_PATTERN)       
         endif
     
         write(*,'(A)') 'Done.'
         write(*,'(A)')
         write(*,'(A)') '----------------Building the ABC matrices--------------'

         call MAKE_ABCS_MATRIX(nnod,length_abc,I_ABC,J_ABC,M_ABC_U,M_ABC_V, &
                             nelem, nelem_abc, ielem_abc, nedge_abc, iedge_abc, & 
                             con_nnz_bc, con_spx_bc, con_nnz, con_spx, nmat, tag_mat, prop_mat, sdeg_mat, &
                             alfa1, alfa2, beta1, beta2, gamma1, gamma2, xx_spx, yy_spx)

         write(*,'(A)') 'Done'
       

      endif
      
!********************************************************************************************************
!     MAKE LOCAL DG MATRIX
!********************************************************************************************************
!      write(*,*) nload_dg_el
!      read(*,*)

      
    nelem_dg = 0;     nnode_dg = 0;
    
    if (nload_dg_el .ne. 0) then 
         allocate(i4count(nnod));       i4count = 0;

    
         call GET_NODE_FROM_FACE(nnod, con_nnz_bc, con_spx_bc, nload_dg_el, tag_dg_el,&
                          nnode_dg, i4count)

         ! output: - number of dg local elements 
         !         - number of dg global elements 

          call GET_DIME_DG(nmat, sdeg_mat, tag_mat, con_nnz, con_spx, &
                          nnod, xx_spx, yy_spx, nelem_dg, i4count)

          allocate(faces(3,nelem_dg), area_nodes(9,nelem_dg))  
          faces = 0; area_nodes = 0.d0
      
          if(nelem_dg .gt. 0) then

             file_face = 'FACES.input'

             call SETUP_DG(nmat, sdeg_mat, tag_mat, con_nnz, con_spx, &
                       nnod, nelem, xx_spx, yy_spx, nelem_dg, i4count,&
                       alfa1, alfa2, beta1, beta2, gamma1, gamma2, delta1, delta2,&
                       faces, area_nodes)
     
             inquire(file=file_face, exist=filefound)
             if(filefound .eqv. .FALSE.) then
                 
                write(*,'(A)') 'Writing FACES.input'
                open(400,file=file_face)
                  do j = 1, nelem_dg
                    write(400,"(1I2,1X,1I12,1X,1I2,9(2X,ES16.9))") &
                         faces(1,j), faces(2,j), faces(3,j), &
                         area_nodes(1,j), area_nodes(2,j), area_nodes(3,j), &
                         area_nodes(4,j), area_nodes(5,j), area_nodes(6,j), &
                         area_nodes(7,j), area_nodes(8,j), area_nodes(9,j)
                  enddo
                close(400)
                 
             endif  
              
                   
             head_file = 'DGFS.input'
             inquire(file=head_file, exist=filefound)
             if(filefound .eqv. .FALSE.) then     
              
                write(*,'(A)') 'Writing DGFS.input'
                   
                ! output: - write DGFS.input file
        
                allocate(dg_els(nelem_dg), scratch_dg_els(nelem_dg)) 
        
                call SETUP_DG_ELEM(nmat, sdeg_mat, tag_mat, con_nnz, con_spx, &
                                   nnod, nelem, xx_spx,yy_spx,&
                                   nelem_dg, i4count, &
                                   alfa1, alfa2,beta1, beta2, gamma1, gamma2, delta1, delta2,&
                                   dg_els, scratch_dg_els, &
                                   tag_dg_el, tag_dg_yn, nload_dg_el, &
                                   con_bc, nedge)

        
                call WRITE_FILE_DGFS(nmat, sdeg_mat, tag_mat, con_nnz, con_spx, &
                                   nnod, nelem, xx_spx, yy_spx,&
                                   nelem_dg, &
                                   alfa1, alfa2, beta1, beta2, gamma1, gamma2, delta1, delta2, &
                                   faces, area_nodes, dg_els, scratch_dg_els, &
                                   head_file)

               deallocate(dg_els, scratch_dg_els) 
        
        
             endif
                        

             allocate(el_new(nelem_dg))  

             write(*,'(A)') 
             write(*,'(A)') '-----------------Making DG interfaces------------------' 

             call MAKE_DG_INTERFACE(nmat, sdeg_mat, tag_mat, prop_mat, con_nnz, con_spx, &
                                 nnod, nelem, xx_spx, yy_spx, &
                                 nelem_dg, i4count, &
                                 alfa1, alfa2, beta1, beta2, gamma1, gamma2, &
                                 delta1, delta2, dg_const, dg_pen, & 
                                 faces, area_nodes, el_new, head_file, test)
 
 
            write(*,'(A)') 'Done.'                                     
          endif


          deallocate(faces, area_nodes,i4count)
      
      
      
!********************************************************************************************************
!     MAKE GLOBAL DG MATRIX IN CRS SPARSE FORMAT
!********************************************************************************************************
      if(nelem_dg .gt. 0) then
        
        nnz_dg_total = 0; 

        do i = 1, nelem_dg
           nnz_dg_total = nnz_dg_total + el_new(i)%nnz_plus + el_new(i)%nnz_minus
        enddo
        
        allocate(IDG_TOTAL(nnz_dg_total),JDG_TOTAL(nnz_dg_total),MDG_TOTAL(nnz_dg_total))

        
        call MAKE_DG_SPARSE_TOTAL(nelem_dg, el_new, nnz_dg_total, con_nnz, con_spx, &
                                  nnod, nmat, sdeg_mat, IDG_TOTAL, &
                                  JDG_TOTAL, MDG_TOTAL)
                                  
        call COUNT_EFFECTIVE_LENGTH(nnz_dg_total,IDG_TOTAL,JDG_TOTAL,MDG_TOTAL,nnz_dg)
                                  
        allocate(IDG_MORSE(nnz_dg), JDG_MORSE(nnz_dg), MDG_MORSE(nnz_dg))                          

        call MAKE_DG_SPARSE(nnz_dg_total,IDG_TOTAL,JDG_TOTAL,MDG_TOTAL,nnz_dg,IDG_MORSE,JDG_MORSE,MDG_MORSE)
                          
        !Convert sparse matrix into RCS matrix
        allocate(IDG(0:2*nnod), JDG(nnz_dg), MDG(nnz_dg))                  
        
        
        call MORSE_2_RCS(nnod, nnz_dg, IDG_MORSE, JDG_MORSE, MDG_MORSE, &
                         IDG, JDG, MDG)
                 
        deallocate(IDG_TOTAL,JDG_TOTAL,MDG_TOTAL,IDG_MORSE,JDG_MORSE,MDG_MORSE)


        if(test .eq. 1) then
           nnz_dg_total_only_uv = 0; 
        
           do i = 1, nelem_dg
              nnz_dg_total_only_uv = nnz_dg_total_only_uv + &
                                     el_new(i)%nnz_plus_only_uv + el_new(i)%nnz_minus_only_uv
           enddo
        
           allocate(IDG_TOTAL(nnz_dg_total_only_uv),JDG_TOTAL(nnz_dg_total_only_uv),&
                    MDG_TOTAL(nnz_dg_total_only_uv))

        
           call MAKE_DG_SPARSE_TOTAL_ONLY_UV(nelem_dg, el_new, nnz_dg_total_only_uv, con_nnz, con_spx, &
                                             nnod, nmat, sdeg_mat, IDG_TOTAL, &
                                             JDG_TOTAL, MDG_TOTAL)
                                  
           call COUNT_EFFECTIVE_LENGTH(nnz_dg_total_only_uv,IDG_TOTAL,JDG_TOTAL,&
                                       MDG_TOTAL, nnz_dg_only_uv)
                                  
           allocate(IDG_MORSE(nnz_dg_only_uv), JDG_MORSE(nnz_dg_only_uv), MDG_MORSE(nnz_dg_only_uv))                          

           call MAKE_DG_SPARSE(nnz_dg_total_only_uv,IDG_TOTAL,JDG_TOTAL,MDG_TOTAL,&
                               nnz_dg_only_uv,IDG_MORSE,JDG_MORSE,MDG_MORSE)
                          
           !Convert sparse matrix into RCS matrix
           allocate(IDG_only_uv(0:2*nnod), JDG_only_uv(nnz_dg_only_uv), MDG_only_uv(nnz_dg_only_uv))                  
        
        
           call MORSE_2_RCS(nnod, nnz_dg_only_uv, IDG_MORSE, JDG_MORSE, MDG_MORSE, &
                           IDG_only_uv, JDG_only_uv, MDG_only_uv)
                 
           deallocate(IDG_TOTAL,JDG_TOTAL,MDG_TOTAL,IDG_MORSE,JDG_MORSE,MDG_MORSE)

        endif

                    
      endif   
     endif
      

!********************************************************************************************************
!     BUILDING GLOBAL MATRICES -- LEGEND:
!     M = mass matrix;  C,D = damping matrix; R,S = abc matrix; A = stiffness matrix; B = dg matrix 
!                                     MU''  + (C-S)U' + (A+B+D-R)U = F 
!     M = M_MASS
!     C = C_MASS
!     D = D_MASS
!     S = M_ABC_V
!     R = M_ABC_U
!     A = M_STIFF
!     B = MDG
!********************************************************************************************************

      if(nload_abc_el .eq. 0) then 
         allocate(I_ABC(0:2*nnod), J_ABC(2*nnod),M_ABC_U(2*nnod),M_ABC_V(2*nnod))
         I_ABC = 0;   J_ABC = 0;     M_ABC_U = 0.d0;  M_ABC_V = 0.d0; 
      endif


      write(*,'(A)')
      write(*,'(A)') '-------------------Summing  matrices-------------------'

      allocate(NDEGR(2*nnod),IW(2*nnod))
      
      M_ABC_V = - M_ABC_V;      M_ABC_U = - M_ABC_U;
      I_ABC = I_ABC + 1;        I_MASS = I_MASS + 1;
      
      call aplbdg ( 2*nnod, 2*nnod,  J_MASS, I_MASS, J_ABC, I_ABC, NDEGR, NNZ_AB, IW )
       
      allocate(IC_SUM(0:2*nnod), JC_SUM(NNZ_AB), C_SUM(NNZ_AB))
      allocate(ID_SUM(0:2*nnod), JD_SUM(NNZ_AB), D_SUM(NNZ_AB))
      
      !Computing the nonzero elements for the sum
      call aplb ( 2*nnod, 2*nnod, 0, C_MASS, J_MASS, I_MASS, M_ABC_V, J_ABC, I_ABC, &
                       C_SUM, JC_SUM, IC_SUM, NNZ_AB, IW, ierr)

      call aplb ( 2*nnod, 2*nnod, 0, D_MASS, J_MASS, I_MASS, M_ABC_U, J_ABC, I_ABC, &
                       D_SUM, JD_SUM, ID_SUM, NNZ_AB, IW, ierr)

      !Summing C_SUM = C_MASS - M_ABC_V 
      call aplb ( 2*nnod, 2*nnod, 1, C_MASS, J_MASS, I_MASS, M_ABC_V, J_ABC, I_ABC, &
                       C_SUM, JC_SUM, IC_SUM, NNZ_AB, IW, ierr)

      !Summing D_SUM = D_MASS - M_ABC_U 
      call aplb ( 2*nnod, 2*nnod, 1, D_MASS, J_MASS, I_MASS, M_ABC_U, J_ABC, I_ABC, &
                       D_SUM, JD_SUM, ID_SUM, NNZ_AB, IW, ierr)

      
      I_STIFF = I_STIFF + 1

      !Computing the nonzero elements for the sum
      call aplbdg ( 2*nnod, 2*nnod,  J_STIFF, I_STIFF, JD_SUM, ID_SUM, NDEGR, NNZ_AB, IW )


      allocate(IE_SUM(0:2*nnod), JE_SUM(NNZ_AB), E_SUM(NNZ_AB))
      
      !Summing E_SUM = M_STIFF + D_SUM = M_STIFF + D_MASS - M_ABC_U
      call aplb ( 2*nnod, 2*nnod, 0, M_STIFF, J_STIFF, I_STIFF, D_SUM, JD_SUM, ID_SUM, &
                       E_SUM, JE_SUM, IE_SUM, NNZ_AB, IW, ierr)

      call aplb ( 2*nnod, 2*nnod, 1, M_STIFF, J_STIFF, I_STIFF, D_SUM, JD_SUM, ID_SUM, &
                       E_SUM, JE_SUM, IE_SUM, NNZ_AB, IW, ierr)

      if(nelem_dg .gt. 0) then
        IDG = IDG + 1
        
        !Computing the nonzero elements for the sum
        call aplbdg ( 2*nnod, 2*nnod,  JE_SUM, IE_SUM, JDG, IDG, NDEGR, NNZ_AB, IW )

        allocate(IDG_SUM(0:2*nnod), JDG_SUM(NNZ_AB), MDG_SUM(NNZ_AB))
      
        !Summing MDG_SUM = E_SUM + MDG = M_STIFF + MDG + D_MASS - M_ABC_U 
        call aplb ( 2*nnod, 2*nnod, 0, E_SUM, JE_SUM, IE_SUM, MDG, JDG, IDG, &
                       MDG_SUM, JDG_SUM, IDG_SUM, NNZ_AB, IW, ierr)

        call aplb ( 2*nnod, 2*nnod, 1, E_SUM, JE_SUM, IE_SUM, MDG, JDG, IDG, &
                       MDG_SUM, JDG_SUM, IDG_SUM, NNZ_AB, IW, ierr)

        deallocate(IE_SUM,JE_SUM,E_SUM)
        allocate(IE_SUM(0:2*nnod), JE_SUM(NNZ_AB), E_SUM(NNZ_AB))

        IE_SUM = IDG_SUM; JE_SUM = JDG_SUM; E_SUM = MDG_SUM;
        
        deallocate(IDG_SUM,JDG_SUM,MDG_SUM)

      endif
 
      deallocate(C_MASS, D_MASS, I_STIFF, J_STIFF, M_STIFF, I_ABC, J_ABC, M_ABC_U, M_ABC_V)
      write(*,'(A)') 'Done'

!********************************************************************************************************
!     COMPUTE M^-1*(C-S) AND M^-1*(A+B+D-R)
!********************************************************************************************************

      write(*,'(A)')
      write(*,'(A)') '----------------Multiplying  matrices------------------'
      
      M_MASS = 1./M_MASS;
      
      !Computing the nonzero elements for the mul      
      call amubdg ( 2*nnod, 2*nnod, 2*nnod, J_MASS, I_MASS, JC_SUM, IC_SUM, NDEGR, NNZ_AB, IW )
     
      allocate(IN_TOT(0:2*nnod), JN_TOT(NNZ_AB), N_TOT(NNZ_AB))

      !Multiplying N = M^-1*(C-S)      
      call amub ( 2*nnod, 2*nnod, 0, M_MASS, J_MASS, I_MASS, C_SUM, JC_SUM, IC_SUM, &
                  N_TOT, JN_TOT, IN_TOT, NNZ_AB, IW, ierr )

      call amub ( 2*nnod, 2*nnod, 1, M_MASS, J_MASS, I_MASS, C_SUM, JC_SUM, IC_SUM, &
                  N_TOT, JN_TOT, IN_TOT, NNZ_AB, IW, ierr )

      NNZ_N = NNZ_AB
      
      !Computing the nonzero elements for the mul      
      call amubdg ( 2*nnod, 2*nnod, 2*nnod, J_MASS, I_MASS, JE_SUM, IE_SUM, NDEGR, NNZ_AB, IW )

      allocate(IK_TOT(0:2*nnod), JK_TOT(NNZ_AB), K_TOT(NNZ_AB))

      !Multiplying K = M^-1*(A+B+D-R)
      call amub ( 2*nnod, 2*nnod, 0, M_MASS, J_MASS, I_MASS, E_SUM, JE_SUM, IE_SUM, &
                  K_TOT, JK_TOT, IK_TOT, NNZ_AB, IW, ierr )

      call amub ( 2*nnod, 2*nnod, 1, M_MASS, J_MASS, I_MASS, E_SUM, JE_SUM, IE_SUM, &
                  K_TOT, JK_TOT, IK_TOT, NNZ_AB, IW, ierr )

      NNZ_K = NNZ_AB

      deallocate(M_MASS, I_MASS, J_MASS, C_SUM, JC_SUM, IC_SUM, E_SUM, JE_SUM, IE_SUM, NDEGR, IW)
      write(*,'(A)') 'Done'

!********************************************************************************************************
!     BUILDING THE RHS M^-1*F
!********************************************************************************************************

      write(*,'(A)')
      write(*,'(A)') '-------------------Building the RHS--------------------'

      do i = 1, nfunc
         Fel(i,:) = Fel(i,:)/Mel
      enddo
      
      write(*,'(A)') 'Done'

!********************************************************************************************************
!     SETTING CALCULATION PARAMETERS
!********************************************************************************************************

      write(*,'(A)')
      write(*,'(A)') '-----------Setting calculation parameters--------------'

      
      
!     INITIAL CONDITIONS
      
      allocate (u0(2*nnod),v0(2*nnod));   u0 = 0.0d0; v0 = 0.0d0

      if (test .ge. 1) then
         pi = 4.d0*datan(1.d0)
         do i = 1, nnod 
           !u0(i) = (xx_spx(i)**2-1.d0)*(yy_spx(i)**2-1.d0)
           !u0(i+nnod) = 0.d0 
           u0(i) = 0.d0
           u0(i+nnod) = 0.d0 
           v0(i) = - dsqrt(2.d0) * pi * dsin(pi*xx_spx(i))**2 * dsin(2.d0*pi*yy_spx(i)) 
           v0(i+nnod) = dsqrt(2.d0) * pi * dsin(2.d0*pi*xx_spx(i)) * dsin(pi*yy_spx(i))**2

         enddo  
           !v0 = 0.0d0
      endif
      
!     CFL CONDITION
      
      write(*,'(A,E12.4)')'Time step = ',deltat
      call DELTAT_MAX(deltat,nnod,nmat,tag_mat,prop_mat,sdeg_mat,&
                      xx_macro,yy_macro,nelem,con,deltat_cfl,fmax)
                      
      nts = int(xtime / deltat)
      write(*,'(A,I8)')'Number of time-steps = ',nts
      
      xtime = dfloat(nts) * deltat
      write(*,'(A,E12.4)')'Final time = ',xtime
      
      
!     SNAPSHOTS
      
      if (nsnaps.gt.0) then
        do i = 1,nsnaps
          itersnap(i) = int(tsnap(i)/deltat)
          if (itersnap(i).gt.nts) itersnap(i) = nts
        enddo
      endif
      
      
!     MONITORED NODES

      nmonitors = 0
      if (num_lst .eq. 1) then
       
	 file_LS = 'LS.input'
	 call READ_DIME_FILEPG(file_LS,nmonitors)     

	 allocate(n_monitor(nmonitors),dist_monitor_lst(nmonitors))
	 allocate(x_monitor_lst(nmonitors),y_monitor_lst(nmonitors))
	 allocate(x_monitor(nmonitors),y_monitor(nmonitors))

	 call READ_FILEPG(file_LS,nmonitors,x_monitor_lst,y_monitor_lst)		
          
	 if (file_mon_lst.eq.0) then ! NO input file with the position of LST monitors

		do i = 1,nmonitors
			call GET_NEAREST_NODE_PGM(nnod, xx_spx, yy_spx, &
					          x_monitor_lst(i), y_monitor_lst(i),&
						  n_monitor(i), dist_monitor_lst(i), depth_search_mon_lst)	
              
                          x_monitor(i) = xx_spx(n_monitor(i))
                          y_monitor(i) = yy_spx(n_monitor(i))
		enddo

		file_MLST = 'MLST.input'
		call WRITE_FILE_MPGM(file_MLST, nmonitors, n_monitor, x_monitor, y_monitor)

	 else ! YES, it exists an input file with the position of LST monitors

		file_MLST = 'MLST.input'
		call READ_FILE_MPGM(file_MLST, nmonitors, n_monitor, &
					      x_monitor, y_monitor)
 
	 endif

         deallocate(dist_monitor_lst,x_monitor_lst,y_monitor_lst)

      else
         write(*,'(A)') 'MLST key not found!'
      endif

      write(*,'(A)')'Monitored nodes'
      write(*,'(I6,2E14.5,I6)')(i,x_monitor(i),y_monitor(i),n_monitor(i), i=1,nmonitors)
      
      
      call system_clock(COUNT=finish)
      time_in_seconds = float(finish-start)/float(clock(2))
      
      write(*,'(A)')
      write(*,'(A)') '-------------------------------------------------------'
      write(*,'(A,F8.4,A)')'Set-up time = ',time_in_seconds,' s'
      write(*,'(A)') '-------------------------------------------------------'
      write(*,'(A)')
      write(*,'(A)')
      write(*,'(A)') '-------------------------------------------------------'
      write(*,'(A)')'             Beginning of the time-loop                 '
      write(*,'(A)')


         call TIME_LOOP_NEW(nnod,xx_spx,yy_spx,con_nnz,con_spx,&
                        nmat,tag_mat,sdeg_mat,prop_mat,&
                        nelem,alfa1,beta1,gamma1,alfa2,beta2,gamma2,delta1,delta2,&
                        con_nnz_bc,con_spx_bc,&
                        nload_dirX_el,tag_dirX_el,nload_dirY_el,tag_dirY_el,&
                        nload_abc_el,tag_abc_el,&
                        nelem_abc,nedge_abc,ielem_abc,iedge_abc,&
                        nfunc,func_type,func_indx,nfunc_data,func_data,tag_func,&             
                        ndt_mon, &                                                            
      	                K_TOT, IK_TOT, JK_TOT, NNZ_K, &
			N_TOT, IN_TOT, JN_TOT, NNZ_N, Mel,&
                        Fel,u0,v0,&
                        nts,deltat,nmonitors,n_monitor,nsnaps,itersnap,&
                        check_node_sism,check_dist_node_sism,&
                        length_check_node_sism,facsmom,&
                        nload_sism_el,&
                        make_damping_yes_or_not,&
			opt_out_var,test,nelem_dg,&
			IDG_only_uv, JDG_only_uv, MDG_only_uv,nnz_dg_only_uv)
			
      write(*,'(A)')
      write(*,'(A)')'Bye.'
      
      
      deallocate (tag_mat,sdeg_mat,prop_mat)
      deallocate (xx_macro,yy_macro,con)
      deallocate (xx_spx,yy_spx,con_spx)
      deallocate (alfa1,beta1,gamma1,delta1,alfa2,beta2,gamma2,delta2)
      deallocate (Fel,u0,v0)
      if (make_damping_yes_or_not .eq. 1) deallocate(Cel,KCel)
      if (nedge_abc.gt.0) deallocate(iedge_abc)
      if (nelem_abc.gt.0) deallocate(ielem_abc)

      if (nmonitors.gt.0) deallocate(x_monitor,y_monitor,n_monitor)
      if (nsnaps.gt.0) deallocate(tsnap,itersnap)

      if (nload_dirX_el.gt.0) deallocate (val_dirX_el,fun_dirX_el,tag_dirX_el)
      if (nload_dirY_el.gt.0) deallocate (val_dirY_el,fun_dirY_el,tag_dirY_el)
      if (nload_neuX_el.gt.0) deallocate (val_neuX_el,fun_neuX_el,tag_neuX_el)
      if (nload_neuY_el.gt.0) deallocate (val_neuY_el,fun_neuY_el,tag_neuY_el)
      if (nload_poiX_el.gt.0) deallocate (val_poiX_el,fun_poiX_el)
      if (nload_poiY_el.gt.0) deallocate (val_poiY_el,fun_poiY_el)
      if (nedge.gt.0) deallocate (con_bc,con_spx_bc)
      if (n_test.gt.0) deallocate (fun_test)      

      deallocate(IN_TOT, JN_TOT, N_TOT)
      deallocate(IK_TOT, JK_TOT, K_TOT)

      
      
      end program SPEED2D
