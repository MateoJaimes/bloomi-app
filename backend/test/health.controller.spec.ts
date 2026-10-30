import { Test } from '@nestjs/testing';
import { HealthController } from '../src/health.controller';

describe('HealthController', () => {
  it('reports the API as ready for requests', async () => {
    const module = await Test.createTestingModule({ controllers: [HealthController] }).compile();
    const controller = module.get(HealthController);
    expect(controller.health()).toEqual({ status: 'ok', service: 'bloomi-api' });
    await module.close();
  });
});
