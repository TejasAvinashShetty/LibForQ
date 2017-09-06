!-----------------------------------------------------------------------------------------------------------------------------------
!                                                        Entropies
!-----------------------------------------------------------------------------------------------------------------------------------
real(8) function purity(d, rho)  ! Returns the purity of a density matrix: P = Tr(rho*rho)
integer, intent(in) :: d  ! Dimension of the density matrix
complex(8), intent(in) :: rho(1:d,1:d)  ! Density matrix
real(8) :: trace_he  ! Trace function
integer :: j, k  ! Auxiliary variables for counters

!purity = trace_he(d, matmul(rho,rho))  ! unoptimized calculation
! more optimized one ( P = sum_jk |rho_jk|^2 )
purity = 0.d0
do j = 1, d ;   do k = 1, d
  purity = purity + (dble(rho(j,k)))**2.d0 + (aimag(rho(j,k)))**2.d0
enddo ;   enddo

end
!------------------------------------------------------------------------------------------------------------------------------------
real(8) function neumann(d, rho) ! Returns the von Neumann entropy of a density matrix
implicit none
integer, intent(in) :: d  ! Dimension of the density matrix
complex(8), intent(in) :: rho(1:d,1:d)  ! Density matrix
complex(8), allocatable :: A(:,:)  ! Auxiliary matrices for LAPACK calling
real(8), allocatable :: W(:)  ! Vector of eigenvalues coming from LAPACK eigensolver
real(8) :: shannon  ! Variables for the shannon and von Neumann entropies

allocate( A(1:d,1:d), W(1:d))
A = rho ;   call lapack_zheevd('N', d, A, W) ;   neumann = shannon(d, W)
deallocate( A, W )

end
!------------------------------------------------------------------------------------------------------------------------------------
real(8) function shannon(d, pv)  ! Returns the Shannon entropy of a probability vector
implicit none
integer, intent(in) :: d  ! Dimension of the probability vector
real(8), intent(in) :: pv(1:d)  ! probability vector
real(8) :: log2  ! Base two log function
integer :: j  ! Auxiliary variable for counters

shannon = 0.d0
do j = 1, d ;   if( (pv(j) > 1.d-15) .and. (pv(j) < (1.d0-1.d-15)) ) shannon = shannon - pv(j)*log2(pv(j)) ;   end do

end
!------------------------------------------------------------------------------------------------------------------------------------
real(8) function mutual_information(da, db, rho) ! Returns the mutual information of the bipartite state rho
implicit none
integer, intent(in) :: da, db  ! Dimension of the sub-systems
complex(8), intent(in) :: rho(1:da*db,1:da*db)  ! The bipartite density matrix
complex(8), allocatable :: rho_a(:,:), rho_b(:,:)  ! The reduced density matrices
real(8) :: neumann  ! For the von Neumman entropy function

allocate( rho_a(1:da,1:da), rho_b(1:db, 1:db) )
call partial_trace_a_he(rho, da, db, rho_b) ;   call partial_trace_b_he(rho, da, db, rho_a)
mutual_information = neumann(da, rho_a) + neumann(db, rho_b) - neumann(da*db, rho)
deallocate( rho_a, rho_b)

end
!------------------------------------------------------------------------------------------------------------------------------------
real(8) function fisher(d, rho, Ob) ! Returns the quantum Fisher information of rho for an observable Ob
implicit none
integer :: d  ! Dimension of rho and Ob
complex(8) :: rho(1:d,1:d), Ob(1:d,1:d) ! The bipartite density matrix and the observable, both given in the computational basis
complex(8), allocatable :: A(:,:)  ! Auxiliary matrix for sending rho to Lapack and for returning its eigenvectors
real(8), allocatable :: W(:)  ! For the eigenvalues of rho
complex(8) :: sandwhich, sw  ! For the function <psi|A|phi>
integer :: j, k  ! Auxiliary variables for counters

allocate( A(1:d,1:d), W(1:d) ) ;   A = rho ;   call lapack_zheevd('V', d, A, W)
fisher = 0.d0
do j = 1, d-1 ;   do k = j+1, d
   sw = sandwhich(d, d, A(:,j), Ob, A(:,k)) ;   fisher = fisher + (((W(j)-W(k))**2.d0)/(W(j)+W(k)))*((abs(sw))**2.d0)
enddo ;   enddo
deallocate ( A, W )

end
!-----------------------------------------------------------------------------------------------------------------------------------