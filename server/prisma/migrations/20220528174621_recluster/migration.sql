-- CreateEnum
CREATE TYPE "NodeStatus" AS ENUM ('ACTIVE', 'ACTIVE_WORKING', 'INACTIVE', 'ERROR');

-- CreateEnum
CREATE TYPE "InterfaceWol" AS ENUM ('a', 'b', 'd', 'g', 'm', 'p', 's', 'u');

-- CreateEnum
CREATE TYPE "CpuArchitecture" AS ENUM ('x86_64');

-- CreateEnum
CREATE TYPE "CpuVendor" AS ENUM ('AMD', 'INTEL');

-- CreateTable
CREATE TABLE "Node" (
    "id" TEXT NOT NULL,
    "ram" BIGINT NOT NULL,
    "cpuId" TEXT NOT NULL,
    "status" "NodeStatus" NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Node_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Disk" (
    "id" TEXT NOT NULL,
    "nodeId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "size" BIGINT NOT NULL,

    CONSTRAINT "Disk_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Interface" (
    "id" TEXT NOT NULL,
    "nodeId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "speed" BIGINT NOT NULL,
    "wol" "InterfaceWol"[],

    CONSTRAINT "Interface_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Cpu" (
    "id" TEXT NOT NULL,
    "architecture" "CpuArchitecture" NOT NULL,
    "flags" TEXT[],
    "cores" SMALLINT NOT NULL,
    "vendor" "CpuVendor" NOT NULL,
    "family" SMALLINT NOT NULL,
    "model" SMALLINT NOT NULL,
    "name" TEXT NOT NULL,
    "cache_l1d" INTEGER NOT NULL,
    "cache_l1i" INTEGER NOT NULL,
    "cache_l2" INTEGER NOT NULL,
    "cache_l3" INTEGER NOT NULL,
    "vulnerabilities" TEXT[],
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "Cpu_pkey" PRIMARY KEY ("id")
);

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
ALTER TABLE "Disk" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Interface" ADD CONSTRAINT "node_id" FOREIGN KEY ("nodeId") REFERENCES "Node"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
