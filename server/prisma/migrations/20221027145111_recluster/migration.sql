-- CreateEnum
CREATE TYPE "UserRoles" AS ENUM ('ADMIN', 'SIMPLE');

-- CreateEnum
CREATE TYPE "UserPermissions" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "NodeRoles" AS ENUM ('RECLUSTER_MASTER', 'K8S_MASTER', 'K8S_WORKER');

-- CreateEnum
CREATE TYPE "NodePermissions" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "NodeStatuses" AS ENUM ('ACTIVE', 'ACTIVE_READY', 'ACTIVE_NOT_READY', 'INACTIVE', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "InterfaceWoLFlags" AS ENUM ('a', 'b', 'd', 'g', 'm', 'p', 's', 'u');

-- CreateEnum
CREATE TYPE "CpuArchitectures" AS ENUM ('x86_64');

-- CreateEnum
CREATE TYPE "CpuVendors" AS ENUM ('AMD', 'INTEL');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "username" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "roles" "UserRoles"[] DEFAULT ARRAY['SIMPLE']::"UserRoles"[],
    "permissions" "UserPermissions"[] DEFAULT ARRAY[]::"UserPermissions"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Node" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "roles" "NodeRoles"[],
    "permissions" "NodePermissions"[] DEFAULT ARRAY[]::"NodePermissions"[],
    "cpuId" UUID NOT NULL,
    "ram" BIGINT NOT NULL,
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
    "status" "NodeStatuses" NOT NULL,
    "reason" TEXT,
    "message" TEXT,
    "last_heartbeat" TIMESTAMPTZ,
    "last_transition" TIMESTAMPTZ NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Status_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Disk" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Disk_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Interface" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "speed" BIGINT NOT NULL,
    "wol" "InterfaceWoLFlags"[] DEFAULT ARRAY[]::"InterfaceWoLFlags"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Interface_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Cpu" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "architecture" "CpuArchitectures" NOT NULL,
    "flags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "cores" INTEGER NOT NULL,
    "vendor" "CpuVendors" NOT NULL,
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

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "Disk_nodeId_name_key" ON "Disk"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Interface_nodeId_name_key" ON "Interface"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Interface_address_key" ON "Interface"("address");

-- CreateIndex
CREATE UNIQUE INDEX "Cpu_vendor_family_model_key" ON "Cpu"("vendor", "family", "model");

-- AddForeignKey
ALTER TABLE "Node" ADD CONSTRAINT "cpu_id" FOREIGN KEY ("cpuId") REFERENCES "Cpu"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Status" ADD CONSTRAINT "Status_id_fkey" FOREIGN KEY ("id") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Disk" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interface" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
