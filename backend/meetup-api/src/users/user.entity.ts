import { Entity, Column, PrimaryGeneratedColumn, CreateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @Column()
  age: number;

  @Column()
  gender: string;

  @Column('text', { array: true })
  interested_in: string[];

  @Column('text', { array: true })
  interests: string[];

  @Column({ nullable: true })
  bio: string;

  @Column('text', { array: true, nullable: true })
  images: string[];

  @Column({ nullable: true, unique: true })
  face_hash: string;

  @Column({ default: false })
  is_verified: boolean;

  @Column('geography', { spatialFeatureType: 'Point', srid: 4326, nullable: true })
  location: object;

  @Column({ type: 'timestamp', nullable: true })
  location_updated_at: Date;

  @Column({ default: false })
  live_location_enabled: boolean;

  @Column({ type: 'timestamp', nullable: true })
  premium_until: Date;

  @Column({ type: 'timestamp', default: () => 'CURRENT_TIMESTAMP' })
  last_active: Date;

  @Column({ unique: true })
  firebase_uid: string;

  @CreateDateColumn()
  created_at: Date;
}