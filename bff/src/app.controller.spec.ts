import { Test, TestingModule } from '@nestjs/testing';
import { AppController } from './app.controller';
import { AppService } from './app.service';

describe('AppController', () => {
  let appController: AppController;
  let appService: AppService;

  beforeEach(async () => {
    const mockAppService = {
      getHello: jest.fn().mockReturnValue('Hello World'),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AppController],
      providers: [
        {
          provide: AppService,
          useValue: mockAppService,
        },
      ],
    }).compile();

    appController = module.get<AppController>(AppController);
    appService = module.get<AppService>(AppService);
  });

  describe('getHello', () => {
    it('should return the value from appService.getHello()', () => {
      // Act
      const result = appController.getHello();

      // Assert
      expect(result).toBe('Hello World');
      expect(appService.getHello).toHaveBeenCalled();
    });
  });

  describe('getHello2', () => {
    it('should return "Hello from /hello"', () => {
      // Act
      const result = appController.getHello2();

      // Assert
      expect(result).toBe('Hello from /hello');
    });
  });
});