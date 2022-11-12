-- CreateEnum
CREATE TYPE "UserRoleEnum" AS ENUM ('ADMIN', 'SIMPLE');

-- CreateEnum
CREATE TYPE "UserPermissionEnum" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "NodeRoleEnum" AS ENUM ('RECLUSTER_CONTROLLER', 'K8S_CONTROLLER', 'K8S_WORKER');

-- CreateEnum
CREATE TYPE "NodePermissionEnum" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "NodeStatusEnum" AS ENUM ('ACTIVE', 'ACTIVE_READY', 'ACTIVE_NOT_READY', 'ACTIVE_DELETE', 'BOOTING', 'INACTIVE', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "WoLFlagEnum" AS ENUM ('a', 'b', 'd', 'g', 'm', 'p', 's', 'u');

-- CreateEnum
CREATE TYPE "CpuArchitectureEnum" AS ENUM ('AMD64', 'ARM64');

-- CreateEnum
CREATE TYPE "CpuVendorEnum" AS ENUM ('AMD', 'INTEL');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "username" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "roles" "UserRoleEnum"[] DEFAULT ARRAY['SIMPLE']::"UserRoleEnum"[],
    "permissions" "UserPermissionEnum"[] DEFAULT ARRAY[]::"UserPermissionEnum"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Node" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "roles" "NodeRoleEnum"[],
    "permissions" "NodePermissionEnum"[] DEFAULT ARRAY[]::"NodePermissionEnum"[],
    "address" TEXT NOT NULL,
    "hostname" TEXT NOT NULL,
    "cpuId" UUID NOT NULL,
    "memory" BIGINT NOT NULL,
    "nodePoolId" UUID NOT NULL,
    "node_pool_assigned" BOOLEAN NOT NULL DEFAULT false,
    "min_power_consumption" INTEGER NOT NULL,
    "max_efficiency_power_consumption" INTEGER,
    "min_performance_power_consumption" INTEGER,
    "max_power_consumption" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Node_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Status" (
    "id" UUID NOT NULL,
    "status" "NodeStatusEnum" NOT NULL,
    "reason" TEXT,
    "message" TEXT,
    "last_heartbeat" TIMESTAMPTZ,
    "last_transition" TIMESTAMPTZ NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Status_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Storage" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Storage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Interface" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "speed" BIGINT NOT NULL,
    "wol" "WoLFlagEnum"[] DEFAULT ARRAY[]::"WoLFlagEnum"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Interface_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Cpu" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "architecture" "CpuArchitectureEnum" NOT NULL,
    "flags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "cores" INTEGER NOT NULL,
    "vendor" "CpuVendorEnum" NOT NULL,
    "family" INTEGER NOT NULL,
    "model" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "cache_l1d" INTEGER NOT NULL,
    "cache_l1i" INTEGER NOT NULL,
    "cache_l2" INTEGER NOT NULL,
    "cache_l3" INTEGER NOT NULL,
    "vulnerabilities" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "single_thread_score" INTEGER NOT NULL,
    "multi_thread_score" INTEGER NOT NULL,
    "efficiency_threshold" INTEGER,
    "performance_threshold" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Cpu_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "NodePool" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "auto_scale" BOOLEAN NOT NULL DEFAULT true,
    "min_nodes" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "NodePool_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Node_name_key" ON "Node"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Node_address_key" ON "Node"("address");

-- CreateIndex
CREATE UNIQUE INDEX "Node_hostname_key" ON "Node"("hostname");

-- CreateIndex
CREATE UNIQUE INDEX "Storage_nodeId_name_key" ON "Storage"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Interface_nodeId_name_key" ON "Interface"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Interface_address_key" ON "Interface"("address");

-- CreateIndex
CREATE UNIQUE INDEX "Cpu_vendor_family_model_key" ON "Cpu"("vendor", "family", "model");

-- CreateIndex
CREATE UNIQUE INDEX "NodePool_name_key" ON "NodePool"("name");

-- AddForeignKey
ALTER TABLE "Node" ADD CONSTRAINT "cpu_id" FOREIGN KEY ("cpuId") REFERENCES "Cpu"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Node" ADD CONSTRAINT "node_pool_id" FOREIGN KEY ("nodePoolId") REFERENCES "NodePool"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Status" ADD CONSTRAINT "Status_id_fkey" FOREIGN KEY ("id") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Storage" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interface" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
