import { Controller, Get, Header } from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @Header('Content-Type', 'text/html')
  getRoot(): string {
    return `<!doctype html><html><head><meta charset="utf-8"><title>NestJS Demo</title></head><body><h1>Welcome to NestJS Demo</h1><p>Running in Docker on port 3000</p></body></html>`;
  }
}
