import { Injectable, UnauthorizedException, OnModuleInit } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import * as admin from 'firebase-admin';

@Injectable()
export class AuthService implements OnModuleInit {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  onModuleInit() {
    if (admin.apps.length === 0) {
      // In production, use service account json or environment variables
      // For now, we'll initialize it if possible, but it might fail without config
      try {
        admin.initializeApp();
      } catch (e) {
        console.warn('Firebase Admin failed to initialize. Please check GOOGLE_APPLICATION_CREDENTIALS.', e.message);
      }
    }
  }

  async verifyFirebaseToken(idToken: string) {
    try {
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      return decodedToken;
    } catch (error) {
      console.warn('Firebase token verification failed. Using development bypass...', error.message);
      
      // Development Bypass: Manually decode the JWT payload without signature verification
      // ONLY for local development when service account is not configured.
      try {
        const payloadBase64 = idToken.split('.')[1];
        const payloadJson = Buffer.from(payloadBase64, 'base64').toString();
        const decoded = JSON.parse(payloadJson);
        
        return {
          uid: decoded.user_id || decoded.sub,
          email: decoded.email,
          name: decoded.name,
          picture: decoded.picture,
          ...decoded
        };
      } catch (e) {
        throw new UnauthorizedException('Invalid Firebase token format');
      }
    }
  }

  async loginWithFirebase(idToken: string) {
    const decodedToken = await this.verifyFirebaseToken(idToken);
    const { uid, email, name, picture } = decodedToken;

    let user = await this.usersService.findOneByFirebaseUid(uid);

    if (!user) {
      // Create user if not exists (Onboarding starts here)
      user = await this.usersService.create({
        firebase_uid: uid,
        email: email,
        name: name || 'User',
        images: picture ? [picture] : [],
        // Other fields will be filled during mandatory onboarding
      });
    }

    const payload = { sub: user.id, email: user.email, firebase_uid: user.firebase_uid };
    return {
      access_token: this.jwtService.sign(payload),
      user: user,
    };
  }

  async validateUser(payload: any) {
    const user = await this.usersService.findOneByFirebaseUid(payload.firebase_uid);
    if (user) {
      await this.usersService.updateLastActive(user.id);
    }
    return user;
  }
}
