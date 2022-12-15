-- CreateEnum
CREATE TYPE "user_role_enum" AS ENUM ('ADMIN', 'SIMPLE');

-- CreateEnum
CREATE TYPE "user_permission_enum" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "node_role_enum" AS ENUM ('RECLUSTER_CONTROLLER', 'K8S_CONTROLLER', 'K8S_WORKER');

-- CreateEnum
CREATE TYPE "node_permission_enum" AS ENUM ('UNKNOWN');

-- CreateEnum
CREATE TYPE "node_status_enum" AS ENUM ('ACTIVE', 'ACTIVE_READY', 'ACTIVE_NOT_READY', 'ACTIVE_DELETING', 'BOOTING', 'INACTIVE', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "wol_flag_enum" AS ENUM ('a', 'b', 'g', 'm', 'p', 's', 'u');

-- CreateEnum
CREATE TYPE "cpu_architecture_enum" AS ENUM ('AMD64', 'ARM64');

-- CreateEnum
CREATE TYPE "cpu_vendor_enum" AS ENUM ('AMD', 'INTEL');

-- CreateTable
CREATE TABLE "user" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "username" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "roles" "user_role_enum"[] DEFAULT ARRAY['SIMPLE']::"user_role_enum"[],
    "permissions" "user_permission_enum"[] DEFAULT ARRAY[]::"user_permission_enum"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "node" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "roles" "node_role_enum"[],
    "permissions" "node_permission_enum"[] DEFAULT ARRAY[]::"node_permission_enum"[],
    "address" TEXT NOT NULL,
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

    CONSTRAINT "node_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "status" (
    "id" UUID NOT NULL,
    "status" "node_status_enum" NOT NULL,
    "reason" TEXT,
    "message" TEXT,
    "last_heartbeat" TIMESTAMPTZ,
    "last_transition" TIMESTAMPTZ NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "status_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "storage" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "size" BIGINT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "storage_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "interface" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "nodeId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "speed" BIGINT NOT NULL,
    "wol" "wol_flag_enum"[] DEFAULT ARRAY[]::"wol_flag_enum"[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "interface_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cpu" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "architecture" "cpu_architecture_enum" NOT NULL,
    "flags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "cores" INTEGER NOT NULL,
    "vendor" "cpu_vendor_enum" NOT NULL,
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

    CONSTRAINT "cpu_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "node_pool" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "name" TEXT NOT NULL,
    "auto_scale" BOOLEAN NOT NULL DEFAULT true,
    "min_nodes" INTEGER NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "node_pool_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "user_username_key" ON "user"("username");

-- CreateIndex
CREATE UNIQUE INDEX "node_name_key" ON "node"("name");

-- CreateIndex
CREATE UNIQUE INDEX "node_address_key" ON "node"("address");

-- CreateIndex
CREATE UNIQUE INDEX "storage_nodeId_name_key" ON "storage"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "interface_nodeId_name_key" ON "interface"("nodeId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "interface_address_key" ON "interface"("address");

-- CreateIndex
CREATE UNIQUE INDEX "cpu_vendor_family_model_key" ON "cpu"("vendor", "family", "model");

-- CreateIndex
CREATE UNIQUE INDEX "node_pool_name_key" ON "node_pool"("name");

-- AddForeignKey
ALTER TABLE "node" ADD CONSTRAINT "cpu_id" FOREIGN KEY ("cpuId") REFERENCES "cpu"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "node" ADD CONSTRAINT "node_pool_id" FOREIGN KEY ("nodePoolId") REFERENCES "node_pool"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "status" ADD CONSTRAINT "status_id_fkey" FOREIGN KEY ("id") REFERENCES "node"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "storage" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "node"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "interface" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "node"("id") ON DELETE CASCADE ON UPDATE CASCADE;
