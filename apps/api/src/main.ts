import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { NestFactory } from '@nestjs/core';
import { Module, Controller, Get, Post, Param, Body, HttpException, HttpStatus } from '@nestjs/common';
import { scanQueue } from './queue';
import { createScan, getScan } from './store';
import type { ScanRequest, ScanJobPayload } from '@armadillo/types/src/pipeline';

@Controller('/health')
class HealthController {
  @Get()
  health() {
    return { ok: true, service: 'armadillo-api' };
  }
}

@Controller('/api/v1/scans')
class ScanController {
  @Post()
  async create(@Body() body: ScanRequest) {
    if (!body?.projectId || !body?.requestedBy || !Array.isArray(body?.targets) || body.targets.length === 0) {
      throw new HttpException('Invalid scan request payload', HttpStatus.BAD_REQUEST);
    }

    const scanId = randomUUID();
    const now = new Date().toISOString();
    createScan({
      id: scanId,
      projectId: body.projectId,
      requestedBy: body.requestedBy,
      status: 'queued',
      createdAt: now,
      updatedAt: now
    });

    const firstJob: ScanJobPayload = {
      scanId,
      stage: 'naabu',
      request: body
    };

    await scanQueue.add('scan-stage', firstJob, {
      attempts: 2,
      removeOnComplete: 100,
      removeOnFail: 100
    });

    return { scanId, status: 'queued' };
  }

  @Get(':scanId')
  status(@Param('scanId') scanId: string) {
    const scan = getScan(scanId);
    if (!scan) {
      throw new HttpException('Scan not found', HttpStatus.NOT_FOUND);
    }
    return scan;
  }
}

@Module({ controllers: [HealthController, ScanController] })
class AppModule {}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  await app.listen(4000);
  console.log('API listening on http://localhost:4000');
}

bootstrap();
