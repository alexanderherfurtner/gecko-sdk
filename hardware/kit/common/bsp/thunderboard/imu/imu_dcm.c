/***************************************************************************//**
 * @file imu_dcm.c
 * @brief Inertial Measurement Unit DCM matrix related routines
 * @version 5.1.3
 *******************************************************************************
 * @section License
 * <b>Copyright 2016 Silicon Laboratories, Inc. http://www.silabs.com</b>
 *******************************************************************************
 *
 * This file is licensed under the Silicon Labs License Agreement. See the file
 * "Silabs_License_Agreement.txt" for details. Before using this software for
 * any purpose, you must agree to the terms of that agreement.
 *
 ******************************************************************************/

#include <stdint.h>
#include <stdbool.h>

#include <math.h>

#include "thunderboard/imu/imu.h"

/***************************************************************************//**
 * @addtogroup IMU
 * @{
 ******************************************************************************/

/***************************************************************************//**
 * @addtogroup IMU_Functions IMU Functions
 * @{
 ******************************************************************************/

/***************************************************************************//**
 * @brief
 *    Sets the elements of the DCM matrixto the corresponding elements of the
 *    identity matrix
 *
 * @param dcm
 *    DCM matrix
 *
 * @return
 *    None
 ******************************************************************************/
void IMU_dcmReset( float dcm[3][3] )
{

   int x, y;

   for( y = 0; y < 3; y++ ) {
      for( x = 0; x < 3; x++ ) {
         dcm[y][x] = ( x == y ) ? 1 : 0;
      }
   }

   return;

}

/***************************************************************************//**
 * @brief
 *    DCM reset, Z direction
 *
 * @param dcm
 *    DCM matrix
 *
 * @return
 *    None
 ******************************************************************************/
void IMU_dcmResetZ( float dcm[3][3] )
{

   dcm[0][0] = 1;
   dcm[0][1] = 0;
   dcm[0][2] = 0;
   IMU_vectorCrossProduct( &dcm[1][0], &dcm[0][0], &dcm[2][0] );
   IMU_vectorScale       ( &dcm[1][0], -1.0f );
   IMU_vectorCrossProduct( &dcm[0][0], &dcm[1][0], &dcm[2][0] );

   return;

}

/***************************************************************************//**
 * @brief
 *    Rotates the DCM matrix by a given angle
 *
 * @param dcm
 *    DCM matrix
 *
 * @param angle
 *    Rotation angle
 *
 * @return
 *    None
 ******************************************************************************/
void IMU_dcmRotate( float dcm[3][3], float angle[3] )
{

   int x, y;
   float um[3][3];
   float tm[3][3];

   um[0][0] =  0.0f;
   um[0][1] = -angle[2];
   um[0][2] =  angle[1];

   um[1][0] =  angle[2];
   um[1][1] =  0.0f;
   um[1][2] = -angle[0];

   um[2][0] = -angle[1];
   um[2][1] =  angle[0];
   um[2][2] =  0.0f;

   IMU_matrixMultiply( tm, dcm, um );

   for( y = 0; y < 3; y++ ) {
      for( x = 0; x < 3; x++ ) {
         dcm[y][x] += tm[y][x];
      }
   }

   return;

}

/***************************************************************************//**
 * @brief
 *    Normalizes the DCM matrix
 *
 * @param dcm
 *    DCM matrix
 *
 * @return
 *    None
 ******************************************************************************/
void IMU_dcmNormalize( float dcm[3][3] )
{

   float error;
   float renorm;
   float r;
   float temporary[3][3];

   error = -0.5f * IMU_vectorDotProduct( &dcm[0][0], &dcm[1][0] );

   IMU_vectorScalarMultiplication( &temporary[0][0], &dcm[1][0], error );
   IMU_vectorScalarMultiplication( &temporary[1][0], &dcm[0][0], error );

   IMU_vectorAdd( &temporary[0][0], &temporary[0][0], &dcm[0][0] );
   IMU_vectorAdd( &temporary[1][0], &temporary[1][0], &dcm[1][0] );

   IMU_vectorCrossProduct( &temporary[2][0], &temporary[0][0], &temporary[1][0] );

   r      = IMU_vectorDotProduct( &temporary[0][0], &temporary[0][0] );
   renorm = 0.5f * ( 3.0f - r );
   IMU_vectorScalarMultiplication( &dcm[0][0], &temporary[0][0], renorm );

   r      = IMU_vectorDotProduct( &temporary[1][0], &temporary[1][0] );
   renorm = 0.5f * ( 3.0f - r );
   IMU_vectorScalarMultiplication( &dcm[1][0], &temporary[1][0], renorm );

   r      = IMU_vectorDotProduct( &temporary[2][0], &temporary[2][0] );
   renorm = 0.5f * ( 3.0f - r );
   IMU_vectorScalarMultiplication( &dcm[2][0], &temporary[2][0], renorm );

   return;

}

/***************************************************************************//**
 * @brief
 *    Calculates the Euler angles (roll, pitch, yaw) from the DCM matrix
 *
 * @param[in] dcm
 *    DCM matrix
 *
 * @param[out] angle
 *    An array containing the Euler angles
 *
 * @return
 *    None
 ******************************************************************************/
void IMU_dcmGetAngles( float dcm[3][3], float angle[3] )
{

   /* Roll */
   angle[0] =  atan2f( dcm[2][1], dcm[2][2] );

   /* Pitch */
   angle[1] = -asinf( dcm[2][0] );

   /* Yaw */
   angle[2] =  atan2f( dcm[1][0], dcm[0][0] );

   return;

}

/** @} (end addtogroup IMU_Functions) */

/** @} (end addtogroup IMU) */
