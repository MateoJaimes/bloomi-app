import 'reflect-metadata';
import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import helmet from 'helmet';
import type { NextFunction, Request, Response } from 'express';
import { AppModule } from './app.module';
import { authCallbackHtml, authCallbackScript } from './auth/auth-callback.page';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: false });
  const configuredOrigins = (process.env.CORS_ORIGINS ?? 'http://localhost:*,http://127.0.0.1:*')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.use(helmet());
  // Supabase redirects email confirmations to the configured Site URL. In local
  // development that URL may be the API origin, so provide a useful landing page.
  app.use((request: Request, response: Response, next: NextFunction) => {
    if (request.method === 'GET' && request.path === '/auth-callback.js') {
      response.setHeader('Cache-Control', 'no-store');
      response.status(200).type('application/javascript').send(authCallbackScript);
      return;
    }
    if (request.method === 'GET' && request.path === '/') {
      response.setHeader('Cache-Control', 'no-store');
      response.setHeader('Referrer-Policy', 'no-referrer');
      response.status(200).type('html').send(authCallbackHtml);
      return;
    }
    next();
  });
  app.enableCors({
    origin: (origin: string | undefined, callback: (error: Error | null, allow?: boolean) => void) => {
      if (!origin || configuredOrigins.some((allowed) => {
        const pattern = new RegExp(`^${allowed.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replaceAll('\\*', '.*')}$`);
        return pattern.test(origin);
      })) return callback(null, true);
      return callback(new Error('Origen no permitido por CORS'), false);
    },
    methods: ['GET', 'POST', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });
  app.setGlobalPrefix('v1');
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port, '0.0.0.0');
}

void bootstrap();
