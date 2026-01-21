import { Injectable, OnModuleInit } from '@nestjs/common';
import { Repository } from 'typeorm';
import { InjectRepository } from '@nestjs/typeorm';
import { User } from './users/user.entity';

@Injectable()
export class AppService implements OnModuleInit {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  async onModuleInit() {
    // ensure there is at least one user in DB
    const count = await this.usersRepo.count();
    if (count === 0) {
      const u = this.usersRepo.create({ name: 'demo' });
      await this.usersRepo.save(u);
      console.log('Inserted demo user into DB');
    }
  }
}
