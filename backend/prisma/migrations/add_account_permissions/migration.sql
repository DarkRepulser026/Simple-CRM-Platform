-- Migration: Add Account permissions to Permission enum

-- Add new account permissions to the Permission enum
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'VIEW_ACCOUNTS';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'CREATE_ACCOUNTS';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'EDIT_ACCOUNTS';
ALTER TYPE "Permission" ADD VALUE IF NOT EXISTS 'DELETE_ACCOUNTS';
