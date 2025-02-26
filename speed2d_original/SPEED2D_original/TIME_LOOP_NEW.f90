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

!> @brief Perform time integration with leap-frog method.
!! @author Ilario Mazzieri
!> @date April, 2014
!> @version 1.0

!> @param[in] nnt number of nodes
!> @param[in] xs,ys
!> @param[in] cs_nnz length of cs
!> @param[in] cs spectral connectivity vector
!> @param[in] nm number of materials
!> @param[in] tag_mat label for materials
!> @param[in] sdeg_mat pol. degrees
!> @param[in] prop_mat material properties
!> @param[in] alfa,beta,gamma constatn for bilinear map
!> @param[in] cs_nnz_bc length of cs_bc
!> @param[in] cs_bc spectral connectivity vector for boundary
!> @param[in] nl_dirX   number of Dirichlet b.c. (x-dir)
!> @param[in] nl_dirY   number of Dirichlet b.c. (y-dir)
!> @param[in] tag_dirX  label for Dirichlet b.c. (x-dir)
!> @param[in] tag_dirY  label for Dirichlet b.c. (y-dir)
!> @param[in] nelem_abc number of ab elements
!> @param[in] nedge_abc number of ab edges
!> @param[in] ielem_abc index of ab elements 
!> @param[in] iedge_abc index of ab edges
!> @param[in] nf  number of time functions
!> @param[in] func_type type for functions
!> @param[in] func_indx indeces for functions
!> @param[in] nfunc_data number of data for functions
!> @param[in] func_data data for functions
!> @param[in] tag_func label for functions
!> @param[in] ndt_monitor time step for monitors
!> @param[in] K_TOT,IK_TOT,JK_TOT stiffness matrix in morse format
!> @param[in] NNZ_K nnzero el for stiffness matrix
!> @param[in] N_TOT,IN_TOT,JN_TOT damping matrix in morse format
!> @param[in] NNZ_N nnzero el for damping matrix
!> @param[in] mvec mass matrix 
!> @param[in] Fmat external loads
!> @param[in] u0,v1 initial conditions
!> @param[in] nts number of time steps
!> @param[in] dt time step
!> @param[in] nmonit number of monitors
!> @param[in] node_m id for monitors
!> @param[in] nsnap number of snapshots (dummy)
!> @param[in] itersnap dummy
!> @param[in] check_node_sism array for seismic sources
!> @param[in] check_dist_node_sism distance of the node from the seismic source
!> @param[in] length_cns ength check seismic nodes (useless)
!> @param[in] facsmom factor for seismic momentum
!> @param[in] nl_sism number of seismic loads
!> @param[in] make_damping_yes_or_not damping variable
!> @param[in] option_out_var options for output

      subroutine TIME_LOOP_NEW(nnt,xs,ys,cs_nnz,cs,&
                              nm,tag_mat,sdeg_mat,prop_mat,&
                              ne,alfa1,beta1,gamma1,alfa2,beta2,gamma2,delta1,delta2,&
                              cs_nnz_bc,cs_bc,&
                              nl_dirX,tag_dirX,nl_dirY,tag_dirY,&
                              nl_abc,tag_abc,&
                              nelem_abc,nedge_abc,ielem_abc,iedge_abc,&
                              nf,func_type,func_indx,nfunc_data,func_data,tag_func, &
                              ndt_monitor,&
			      K_TOT, IK_TOT, JK_TOT, NNZ_K, &
			      N_TOT, IN_TOT, JN_TOT, NNZ_N, mvec, &
                              Fmat,u0,v1,&
                              nts,dt,nmonit,node_m,nsnap,itersnap,&
                              check_node_sism,check_dist_node_sism,&  
                              length_cns,facsmom,nl_sism,&
                              make_damping_yes_or_not,&
           	              option_out_var,test,nelem_dg,&
           	              IDG_only_uv, JDG_only_uv, MDG_only_uv, nnz_dg_only_uv) 

      implicit none
      
      integer*4 :: NNZ_K, NNZ_N, error, test, nelem_dg,nnz_dg_only_uv
      integer*4, dimension(0:2*nnt) :: IK_TOT, IN_TOT, IDG_only_uv
      integer*4, dimension(nnz_dg_only_uv) :: JDG_only_uv
      integer*4, dimension(NNZ_K) :: JK_TOT
      integer*4, dimension(NNZ_N) :: JN_TOT
      real*8, dimension(NNZ_K) :: K_TOT
      real*8, dimension(NNZ_N) :: N_TOT
      real*8, dimension(nnz_dg_only_uv) :: MDG_only_uv
      integer*4 :: nnt,cs_nnz,nm,ne,cs_nnz_bc,nf
      integer*4 :: nl_dirX,nl_dirY,nl_abc
      integer*4 :: nts,nmonit,nsnap
      integer*4 :: nfunc_data						
      real*8, dimension(nnt) :: xs,ys
      integer*4, dimension(0:cs_nnz) :: cs
      integer*4, dimension(nm) :: tag_mat,sdeg_mat
      real*8, dimension(nm,4) :: prop_mat
      real*8, dimension(ne) :: alfa1,beta1,gamma1,alfa2,beta2,gamma2,delta1,delta2
      integer*4, dimension(0:cs_nnz_bc) :: cs_bc
      integer*4, dimension(nl_dirX) :: tag_dirX
      integer*4, dimension(nl_dirY) :: tag_dirY
      integer*4, dimension(nl_abc) :: tag_abc
      integer*4, dimension(nf) :: func_type
      integer*4, dimension(nf +1) :: func_indx
      real*8, dimension(nfunc_data) :: func_data         
      integer*4, dimension(nf) :: tag_func                
      real*8, dimension(2*nnt) :: mvec
      real*8, dimension(nf,2*nnt) :: Fmat
      real*8, dimension(2*nnt) :: u0,v1
      integer*4, dimension(nmonit) :: node_m
      integer*4, dimension(nsnap) :: itersnap
      real*8 :: dt      
      integer*4, dimension(3) :: clock
      integer*4 :: clock_start,clock_finish
      integer*4 :: isnap,its,fn,ie,nn,ip,im
      integer*4 :: i,is,in,id1,id2,idt,j,jn,k,kn,iaz,jaz,kaz
      real*4 :: time_in_seconds,time_total
      real*8 :: tt0,tt1,tt2,dt2
      real*8 :: r8t,eps,pi
      integer*4 :: i4t
      real*8 :: get_func_value
      real*8, dimension(:), allocatable :: func_value

!********************************************************************************************
!             OUTPUT VARIABLES
!********************************************************************************************

      character*70 :: file_disp, file_vel, file_acc, file_stress, file_strain, file_omega
      integer*4 :: unit_disp, unit_vel, unit_acc, unit_stress, unit_strain, unit_omega
      integer*4, dimension (6) :: option_out_var           

!********************************************************************************************
!             BOUNDARY CONDITIONS
!********************************************************************************************
      
      integer*4, dimension(:), allocatable :: i4count
      integer*4, dimension(:), allocatable :: inode_dirX
      integer*4, dimension(:), allocatable :: inode_dirY
      integer*4, dimension(:), allocatable :: inode_neuX
      integer*4, dimension(:), allocatable :: inode_neuY
      integer*4, dimension(nelem_abc) :: ielem_abc
      integer*4, dimension(nedge_abc) :: iedge_abc
      integer*4 :: nnode_dirX,nnode_dirY,nnode_neuX,nnode_neuY
      integer*4 :: nelem_abc,nedge_abc
      integer*4 :: iedge,nedge,ied1,ied2,iel1,iel2,iel3,iel4
      integer*4 :: edge_ia,edge_ja,edge_ib,edge_jb
      real*8 :: edge_lx,edge_ly,edge_ll,edge_nx,edge_ny
            
!********************************************************************************************
!              ELEMENT BY ELEMENT
!********************************************************************************************

      real*8 :: lambda,mu,rho, gamma
      real*8, dimension(:), allocatable :: ct,ww
      real*8, dimension(:), allocatable :: dxdx_el,dxdy_el,dydx_el,dydy_el
      real*8, dimension(:,:), allocatable :: dd
      real*8, dimension(:,:), allocatable :: ux_el,uy_el
      real*8, dimension(:,:), allocatable :: vx_el,vy_el
      real*8, dimension(:,:), allocatable :: duxdx_el,duxdy_el
      real*8, dimension(:,:), allocatable :: duydx_el,duydy_el
      real*8, dimension(:,:), allocatable :: sxx_el,syy_el,szz_el,sxy_el,fx_el,fy_el
      real*8, dimension(:,:), allocatable :: det_j 	
      real*8, dimension(:,:), allocatable :: mu_el		       
      real*8, dimension(:,:), allocatable :: lambda_el	 

!********************************************************************************************
!               GLOBAL VARIABLES
!********************************************************************************************
      
      real*8, dimension(:), allocatable :: u1,u2
      real*8, dimension(:), allocatable :: fk,fe, fd, sism
      real*8, dimension(:), allocatable :: vel, acc
      real*8, dimension(:), allocatable :: sxx,syy,sxy,szz 
      real*8, dimension(:), allocatable :: duxdx,duydy,duxdy,duydx

!********************************************************************************************
!                  SEISMIC MOMENT
!********************************************************************************************
      
      integer*4 :: length_cns
      integer*4, dimension(length_cns,5) :: check_node_sism
      real*8, dimension(length_cns,1) :: check_dist_node_sism
      integer*4 :: nl_sism 
      real*8, dimension(nl_sism,3) :: facsmom       
      
!********************************************************************************************
!                      DAMPING
!********************************************************************************************
      
      integer*4 :: make_damping_yes_or_not
      real*8 :: ndt_monitor                                   
      integer*4, dimension(:), allocatable :: nodal_counter
      
      pi = 4.d0*datan(1.d0)
      
!********************************************************************************************
!   RESET COUNTER FOR SPARSE MATRIX
!********************************************************************************************
    IK_TOT = IK_TOT - 1
    IN_TOT = IN_TOT - 1
      	      
      ne = cs(0) -1
      if (nf.gt.0) allocate(func_value(nf))  
      
!********************************************************************************************
! Set the number of points where Neumann load is applied (nnode_neuX,nnode_neuY)
! Set the point-id where Neumann load is applied (inode_neuX,inode_neuY)

      allocate(i4count(nnt));       i4count = 0
      eps = 1.0d3 * dabs(epsilon(mvec(1)))
      nnode_neuX = 0;       
      do in = 1,nnt
            id1 = in
            if (nf.gt.0) then
               r8t = 0.0d0
               do fn = 1,nf
                  r8t = r8t + dabs(Fmat(fn,id1))
               enddo
               if (r8t.gt.eps) then
                  nnode_neuX = nnode_neuX + 1
                  i4count(in) = nnode_neuX
               endif
            endif
      enddo

      if (nnode_neuX.gt.0) then
         allocate(inode_neuX(nnode_neuX))
         do in = 1,nnt
            if (i4count(in).ne.0) then
               inode_neuX(i4count(in)) = in
            endif
         enddo
      endif
      
      nnode_neuY = 0;         i4count = 0
      
      do in = 1,nnt
         id2 = in + nnt
            
            if (nf.gt.0) then
               r8t = 0.0d0
               do fn = 1,nf
                  r8t = r8t + dabs(Fmat(fn,id2))
               enddo
               if (r8t.gt.eps) then
                  nnode_neuY = nnode_neuY +1
                  i4count(in) = nnode_neuY
               endif
            endif
      enddo
      
      if (nnode_neuY.gt.0) then
         allocate(inode_neuY(nnode_neuY))
         do in = 1,nnt
            if (i4count(in).ne.0) then
               inode_neuY(i4count(in)) = in
            endif
         enddo
      endif


!********************************************************************************************
! Set the number of points where Dirichlet load is applied (nnode_dirX,nnode_dirY)
! Set the point-id where Dirichlet load is applied (inode_dirX,inode_dirY)

     nnode_dirX = 0;	i4count = 0
      
     call GET_EDGE_NODES(nnt,cs_nnz_bc,cs_bc,nl_dirX,tag_dirX,nnode_dirX,i4count)
      
     if (nnode_dirX.gt.0) then
        allocate(inode_dirX(nnode_dirX))
        do in = 1,nnt
           if (i4count(in).ne.0) then
              inode_dirX(i4count(in)) = in
           endif
        enddo
     endif

     nnode_dirY = 0;     i4count = 0
      
     call GET_EDGE_NODES(nnt,cs_nnz_bc,cs_bc,nl_dirY,tag_dirY,nnode_dirY,i4count)
     
     if (nnode_dirY .gt. 0) then
        allocate(inode_dirY(nnode_dirY))
         do in = 1,nnt
            if (i4count(in).ne.0) then
               inode_dirY(i4count(in)) = in
            endif
         enddo
     endif
     deallocate(i4count)

          
!********************************************************************************************
! SET MONITOR FILES FOR OUTPUT
!********************************************************************************************

      call MAKE_MONITOR_FILES(nmonit,option_out_var)
    
!********************************************************************************************
! INITIALIZATION
!********************************************************************************************
      
      allocate(u1(2*nnt), u2(2*nnt), fk(2*nnt), fe(2*nnt), fd(2*nnt), sism(2*nnt))  
      allocate(vel(2*nnt),acc(2*nnt))

      if(option_out_var(4) .eq. 1) then
          allocate(sxx(nnt), syy(nnt), sxy(nnt), szz(nnt))
          sxx = 0.d0; syy = 0.d0; sxy = 0.d0; szz = 0.d0;
      endif    
      if(option_out_var(5) .eq. 1 .or. option_out_var(6) .eq. 1 ) then
	  allocate(duxdx(nnt), duydy(nnt), duxdy(nnt), duydx(nnt)) 
	  duxdx = 0.d0; duydy = 0.d0; duxdy = 0.d0; duydx = 0.d0;
      endif

     if(option_out_var(4) .eq. 1 .or. option_out_var(5) .eq. 1 .or. option_out_var(6) .eq. 1) then 
       allocate(nodal_counter(nnt)); nodal_counter = 0
       do ie = 1,ne 
	  do j = 1,nn
	     do i = 1,nn 
	        is = nn*(j -1) +i
	        in = cs(cs(ie -1) + is)
	        nodal_counter(in) = nodal_counter(in)+1
             enddo 
	  enddo
       enddo
     endif  

      fe = 0.d0; u1 = 0.d0; u2 = 0.d0; fk = 0.d0; fd = 0.d0  
      vel= v1; acc= 0.0d0; sism = 0.d0

      dt2 = dt*dt
                

!********************************************************************************************
!     ALL STEPS
!********************************************************************************************	  

      do fn = 1,nf
         func_value(fn) = get_func_value(nf,func_type,func_indx,func_data,fn,0.0d0,0.0d0)
      enddo

!      do i = 1, nnt
!        u1(i) = 0.d0;!-dsin(dsqrt(2.d0)*pi*dt) * (dsin(pi*xs(i)))**2 * dsin(2.d0*pi*ys(i))
!        u1(i+nnt) = 0.d0;! dsin(dsqrt(2.d0)*pi*dt) * dsin(2.d0*pi*xs(i)) * (dsin(pi*ys(i)))**2
!      enddo



	   
      do its = 0,nts

         fk = 0.d0; fd = 0.d0; sism = 0.d0;

         call system_clock(COUNT=clock_start,COUNT_RATE=clock(2))
         
         tt0 = dfloat(its -1) * dt
         tt1 = dfloat(its) * dt
         tt2 = dfloat(its +1) * dt

         write(*,'(A,ES16.6)') 'TIME: ', tt1


         if (nnode_neuX.gt.0) then
            do i = 1,nnode_neuX
               in = inode_neuX(i)                 
               fe(in) = 0.0d0
               do fn = 1,nf
                  fe(in) = fe(in) + Fmat(fn,in) * func_value(fn)
               enddo
            enddo
         endif
      
         if (nnode_neuY.gt.0) then
            do i = 1,nnode_neuY
               in = inode_neuY(i) + nnt
               fe(in) = 0.0d0
               do fn = 1,nf
                  fe(in) = fe(in) + Fmat(fn,in) * func_value(fn)
               enddo
            enddo
         endif

!********************************************************************************************
! SEISMIC MOMENT LOAD       
!********************************************************************************************
         if (nl_sism.gt.0) then
           fe = 0.d0;

           do ie = 1,ne

             im = cs(cs(ie -1) +0);   
             rho = prop_mat(im,1)
	     lambda = prop_mat(im,2)
             mu = prop_mat(im,3)

             nn = sdeg_mat(im) +1
             allocate(ct(nn),ww(nn),dd(nn,nn))
             allocate(dxdx_el(nn),dxdy_el(nn),dydx_el(nn),dydy_el(nn))
             allocate(duxdx_el(nn,nn),duxdy_el(nn,nn),duydx_el(nn,nn),duydy_el(nn,nn))
             allocate(sxx_el(nn,nn),syy_el(nn,nn),szz_el(nn,nn),sxy_el(nn,nn))
             allocate(fx_el(nn,nn),fy_el(nn,nn),det_j(nn,nn))					
             allocate(mu_el(nn,nn),lambda_el(nn,nn))	
      
             mu_el = mu; lambda_el = lambda; 

             call lgl(nn,ct,ww,dd)

             sxx_el = 0.d0; syy_el = 0.d0; sxy_el = 0.d0; szz_el = 0.d0;
             fx_el = 0.d0; fy_el = 0.d0;
                 

             do i = 1,nn
                dxdy_el(i) = beta1(ie) + gamma1(ie) * ct(i)
                dydy_el(i) = beta2(ie) + gamma2(ie) * ct(i)
                dxdx_el(i) = alfa1(ie) + gamma1(ie) * ct(i)
                dydx_el(i) = alfa2(ie) + gamma2(ie) * ct(i)
             enddo

             do j = 1,nn
                do i = 1,nn
                   det_j(i,j) = dxdx_el(j)*dydy_el(i) - dxdy_el(i)*dydx_el(j)
                enddo
             enddo

             call MAKE_SEISMIC_MOMENT_NEW(nn,sxx_el,syy_el,szz_el,sxy_el,&
				          check_node_sism,check_dist_node_sism,&
					  length_cns,ie,facsmom,&
					  nl_sism,&
                			  func_type,func_indx,func_data,nf,tt1, &
		                       	  nfunc_data,tag_func)	
		                       	  
		                       	  
	      call MAKE_INTERNAL_FORCE(nn,ct,ww,dd,&
				       dxdx_el,dxdy_el,dydx_el,dydy_el,&				
                                       sxx_el,syy_el,szz_el,sxy_el,fx_el,fy_el)

	      do j = 1,nn
                do i = 1,nn
                  is = nn*(j -1) +i
                  in = cs(cs(ie -1) + is)

                  sism(in) = sism(in) + fx_el(i,j)
                  sism(in+nnt) = sism(in+nnt) + fy_el(i,j)

                enddo
              enddo
              
              deallocate(ct,ww,dd,dxdx_el,dxdy_el,dydx_el,dydy_el)
              deallocate(duxdx_el,duxdy_el,duydx_el,duydy_el)
              deallocate(sxx_el,syy_el,szz_el,sxy_el)
              deallocate(fx_el,fy_el,det_j)					
              deallocate(mu_el,lambda_el)     
              
           enddo  
         endif
         

!********************************************************************************************
! LEAP-FROG        
!********************************************************************************************
        !Damping
        !(u2 - 2*u1 + u0)/dt^2 + N_TOT*(u2-u0)/2dt= - K_TOT*u1 + Fel

        !NO Damping
        !(u2 - 2*u1 + u0)/dt^2  = - K_TOT*u1 + Fel

        
!         if(its .eq. 0) then
!            !Compute fk = K_TOT*u1         
!             call MATMUL_SPARSE(K_TOT, NNZ_K, JK_TOT, IK_TOT, fk, 2*nnt, u0, 2*nnt, error)
!            !Compute fd = N_TOT*v1
!             call MATMUL_SPARSE(N_TOT, NNZ_N, JN_TOT, IN_TOT, fd, 2*nnt, v1, 2*nnt, error)
!             
!             fe = fe + sism/mvec;
!             u1 = u0 + v1 *dt - 0.5d0*((fe - fk - fd)*dt2)
!             !u2 = u0 + 2.d0*v1*dt
             
                          
!         else      
!         
               !Compute fk = K_TOT*u1
               call MATMUL_SPARSE(K_TOT, NNZ_K, JK_TOT, IK_TOT, fk, 2*nnt, u1, 2*nnt, error)       
               !Compute fd = N_TOT*v1
               call MATMUL_SPARSE(N_TOT, NNZ_N, JN_TOT, IN_TOT, fd, 2*nnt, v1, 2*nnt, error)
                  
                fe = fe + sism/mvec;  
                u2 = 2.0d0 * u1 - u0 + dt2*(fe - fk - fd)

!         endif


         do fn = 1,nf
             func_value(fn) = GET_FUNC_VALUE(nf,func_type,func_indx,func_data,fn,tt2,0.0d0)
         enddo

        ! write(*,*) func_value, dsin(sqrt(2.d0)*pi*tt2) 
        ! read(*,*)
 
!********************************************************************************************
! DIRICHLET BOUNDARY CONDITIONS
!********************************************************************************************

         if (nnode_dirX.gt.0) then
            do i = 1,nnode_dirX
               in = inode_dirX(i)
                  u2(in) = 0.0d0; u1(in) = 0.d0; v1(in) = 0.d0;
            enddo
         endif
      
         if (nnode_dirY.gt.0) then
            do i = 1,nnode_dirY
               in = inode_dirY(i) + nnt
                  u2(in) = 0.0d0; u1(in) = 0.d0; v1(in) = 0.d0;
            enddo
         endif
 
         !do i = 1, nnt
         !   write(*,*) xs(i),ys(i)
         !   write(*,*) u2(i), u2(i+nnt)
         !   write(*,*) u1(i), u1(i+nnt)
         !
         !   write(*,*) -dsin(sqrt(2.d0)*pi*tt2) * (dsin(pi*xs(i)))**2 * dsin(2.d0*pi*ys(i)),& 
         !               dsin(sqrt(2.d0)*pi*tt2) * dsin(2.d0*pi*xs(i)) * (dsin(pi*ys(i)))**2
         !   write(*,*) '******************************************'
         !   read(*,*)           
         !enddo
         
         call system_clock(COUNT=clock_finish)
         
         time_in_seconds = float(clock_finish - clock_start) / float(clock(2))
         time_total = time_total + time_in_seconds
         
!********************************************************************************************
! COMPUTE ENERGY ERROR
!********************************************************************************************

!      if (test .eq. 1) then
!        call COMPUTE_ENERGY_ERROR(nnt, u0, v1, tt1, ne, cs, cs_nnz,&
!                                  nm, prop_mat, sdeg_mat, tag_mat, &
!                                  nelem_dg, &
!                                  alfa1,alfa2,beta1,beta2, &
!                                  gamma1,gamma2,delta1,delta2, &
!                                  xs,ys,&
!                                  IDG_only_uv, JDG_only_uv, MDG_only_uv, nnz_dg_only_uv)
!      
!      endif

!********************************************************************************************
!     WRITE OUTPUT FILE
!********************************************************************************************

 	   if (nmonit.ge.1 .and. int(real(its)/ndt_monitor).eq.(real(its)/ndt_monitor))  then
 	   
              if (option_out_var(1) .eq. 1) then   
 	         do i = 1,nmonit
                    unit_disp = 40 + i
                    in = node_m(i)

                    if (dabs(u1(in)).lt.(1.0d-99))     u1(in)= 0.d0
    	            if (dabs(u1(in+nnt)).lt.(1.0d-99)) u1(in+nnt)=0.d0
    	            
    	            file_disp = 'monitorXXXXX.d'  
                    if (i.lt.10) then
                       write(file_disp(8:11),'(a4)')'0000'; write(file_disp(12:12),'(i1)')i;
                    elseif (i.le.99) then
                       write(file_disp(8:10),'(a3)')'000';write(file_disp(11:12),'(i2)')i
                    elseif (i.le.999) then
                       write(file_disp(8:9),'(a2)')'00'; write(file_disp(10:12),'(i3)')i
                    elseif (i.le.9999) then
                       write(file_disp(8:8),'(a1)')'0'; write(file_disp(9:12),'(i4)')i    
                    elseif (i.le.99999) then
                       write(file_disp(8:12),'(i5)')'i'				     
                    endif
    	            open(unit_disp,file=file_disp,position='APPEND')
    	             
                    write(unit_disp,'(ES16.6,ES16.6,ES16.6)') tt1,u1(in),u1(in+nnt)
                    close(unit_disp)
                 enddo
              endif

              if (option_out_var(2) .eq. 1) then   
 	         do i = 1,nmonit
                    unit_vel = 40 + i
                    in = node_m(i)

                    if (dabs(vel(in)).lt.(1.0d-99))     vel(in)= 0.d0
    	            if (dabs(vel(in+nnt)).lt.(1.0d-99)) vel(in+nnt)=0.d0
                    write(unit_vel,'(F6.2,ES16.6,ES16.6)') tt1,vel(in),vel(in+nnt)
                enddo
              endif

              if (option_out_var(3) .eq. 1) then   
 	         do i = 1,nmonit
                    unit_acc = 40 + i
                    in = node_m(i)

                    if (dabs(acc(in)).lt.(1.0d-99))     acc(in)= 0.d0
    	            if (dabs(acc(in+nnt)).lt.(1.0d-99)) acc(in+nnt)=0.d0
                    write(unit_acc,'(F6.2,ES16.6,ES16.6)') tt1,acc(in),acc(in+nnt)
                 enddo
              endif


              if (option_out_var(4) .eq. 1) then
                  do in = 1, nnt  
	             sxx(in) = sxx(in) / nodal_counter(in)
	             syy(in) = syy(in) / nodal_counter(in)
	             sxy(in) = sxy(in) / nodal_counter(in)
	             szz(in) = szz(in) / nodal_counter(in)
                  enddo

	          do i = 1,nmonit	
	             unit_stress = 300000 + i									
                     in = node_m(i)											
 	             if (dabs(sxx(in)).lt.(1.0d-99)) sxx(in)=0.0
 	             if (dabs(syy(in)).lt.(1.0d-99)) syy(in)=0.0
                     if (dabs(sxy(in)).lt.(1.0d-99)) sxy(in)=0.0
 	             if (dabs(szz(in)).lt.(1.0d-99)) szz(in)=0.0

                     write(unit_stress,'(5E16.8)') tt1,sxx(in),syy(in),sxy(in),szz(in)
                  enddo
              endif	


              if (option_out_var(5) .eq. 1) then  !Out Options Scandella 02.07.2007
                 do in = 1, nnt  
                    duxdx(in) = duxdx(in) / nodal_counter(in)
	            duydy(in) = duydy(in) / nodal_counter(in)
	            duxdy(in) = duxdy(in) / nodal_counter(in)
                    duydx(in) = duydx(in) / nodal_counter(in) 
                 enddo 

	         do i = 1,nmonit	 
                    unit_strain = 400000 + i	
                    in = node_m(i) 
  	            if (dabs(duxdx(in)).lt.(1.0d-99)) duxdx(in)=0.0
  	            if (dabs(duydy(in)).lt.(1.0d-99)) duydy(in)=0.0
                    if (dabs(duxdy(in)).lt.(1.0d-99)) duxdy(in)=0.0
	            if (dabs(duydx(in)).lt.(1.0d-99)) duydx(in)=0.0

                    write(unit_strain,'(4E16.8)') tt1,duxdx(in),duydy(in),0.5*(duxdy(in)+duydx(in)) 
                 enddo
              endif

              if (option_out_var(6) .eq. 1) then  !Out Options Scandella 02.07.2007
                 if (option_out_var(5) .ne. 1) then
                    do in = 1, nnt  
                       duxdx(in) = duxdx(in) / nodal_counter(in)
	               duydy(in) = duydy(in) / nodal_counter(in)
	               duxdy(in) = duxdy(in) / nodal_counter(in)
                       duydx(in) = duydx(in) / nodal_counter(in) 
                    enddo 
                 endif
          
	         do i = 1,nmonit	 
                    unit_omega = 500000 + i	
                    in = node_m(i) 
                    if (dabs(duxdy(in)).lt.(1.0d-99)) duxdy(in)=0.0
	            if (dabs(duydx(in)).lt.(1.0d-99)) duydx(in)=0.0

                    write(unit_omega,'(2E16.8)') tt1, 0.5*(duxdy(in)-duydx(in)) 
                 enddo
       	      endif

         endif   


!********************************************************************************************
! UPDATE
!********************************************************************************************
        
        if(its .gt. 0) then
            vel = (u2 - u0) / (2*dt) 
            acc = (u2 - 2*u1 + u0) / (dt*dt)
            v1 = vel;
            u0 = u1
            u1 = u2
        endif    

      enddo


      if (nmonit.ge.1) call CLOSE_OUTPUT_FILES(option_out_var, nmonit, &
                                    unit_disp, unit_vel, unit_acc,&
                                    unit_stress, unit_strain, unit_omega)
      
      write(*,'(A,F8.4,A)')'Mean time-step CPU time= ', &
      time_total / dfloat(nts - 1),' s'
      
            
      deallocate(u1,u2,fk,fe,vel,acc,fd)
      if(option_out_var(4) .eq. 1) deallocate(sxx,syy,sxy,szz)
      if(option_out_var(5) .eq. 1) deallocate(duxdx,duydy,duxdy,duydx) 
      if (nf.gt.0) deallocate(func_value) 
     
      if (nnode_dirX.gt.0) deallocate(inode_dirX)
      if (nnode_dirY.gt.0) deallocate(inode_dirY)
      if (nnode_neuX.gt.0) deallocate(inode_neuX)
      if (nnode_neuY.gt.0) deallocate(inode_neuY)

  
      
      return      
      end subroutine TIME_LOOP_NEW
