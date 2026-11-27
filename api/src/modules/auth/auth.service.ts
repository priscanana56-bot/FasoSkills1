import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { User, RefreshToken, type IUser } from './auth.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { env } from '../../config/env.js';
import { ConflictError, UnauthorizedError, NotFoundError } from '../../core/errors/app-error.js';
import type { RegisterInput, LoginInput, UpdateMeInput, ChangePasswordInput } from './auth.schema.js';

/** Single public shape of a user, identical for register, login and /me. */
function toPublicUser(user: IUser, artisanProfileId?: string) {
  return {
    id: user._id.toString(),
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    role: user.role,
    profilePicture: user.profilePicture,
    isVerified: user.isVerified,
    artisanProfileId,
  };
}

export class AuthService {
  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private generateTokens(user: IUser, artisanProfileId?: string) {
    const payload = {
      id: user._id.toString(),
      email: user.email,
      role: user.role,
      artisanProfileId: artisanProfileId || undefined,
    };

    const accessToken = jwt.sign(payload, env.JWT_ACCESS_SECRET, {
      expiresIn: env.JWT_ACCESS_EXPIRES_IN as any,
    });

    const rawRefreshToken = crypto.randomBytes(40).toString('hex');
    const refreshToken = jwt.sign({ id: user._id.toString(), token: rawRefreshToken }, env.JWT_REFRESH_SECRET, {
      expiresIn: env.JWT_REFRESH_EXPIRES_IN as any,
    });

    return { accessToken, refreshToken, rawRefreshToken };
  }

  public async register(input: RegisterInput) {
    const existing = await User.findOne({ email: input.email.toLowerCase() });
    if (existing) {
      throw new ConflictError('A user with this email already exists');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.password, salt);

    const user = await User.create({
      email: input.email.toLowerCase(),
      phone: input.phone,
      fullName: input.fullName,
      passwordHash,
      role: input.role,
      isVerified: input.role === 'client', // Artisans require validation or complete profile
    });

    let artisanProfileId: string | undefined;
    if (input.role === 'artisan') {
      const profile = await ArtisanProfile.create({
        userId: user._id,
        category: input.categoryId || undefined,
        specialty: input.specialty || '',
        city: input.city || 'Ouagadougou',
        experienceYears: 0,
        bio: '',
        availability: 'Disponible',
        profileStatus: 'incomplete',
      });
      artisanProfileId = profile._id.toString();
    }

    const { accessToken, refreshToken, rawRefreshToken } = this.generateTokens(user, artisanProfileId);

    // Store hashed refresh token
    const tokenHash = this.hashToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await RefreshToken.create({ userId: user._id, tokenHash, expiresAt });

    return {
      user: {
        id: user._id.toString(),
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified,
        artisanProfileId,
      },
      tokens: { accessToken, refreshToken },
    };
  }

  public async login(input: LoginInput) {
    const user = await User.findOne({ email: input.email.toLowerCase() });
    if (!user) {
      throw new UnauthorizedError('Invalid credentials');
    }

    const isMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedError('Invalid credentials');
    }

    let artisanProfileId: string | undefined;
    if (user.role === 'artisan') {
      const profile = await ArtisanProfile.findOne({ userId: user._id });
      if (profile) artisanProfileId = profile._id.toString();
    }

    const { accessToken, refreshToken, rawRefreshToken } = this.generateTokens(user, artisanProfileId);

    const tokenHash = this.hashToken(rawRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await RefreshToken.create({ userId: user._id, tokenHash, expiresAt });

    return {
      user: {
        id: user._id.toString(),
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        isVerified: user.isVerified,
        artisanProfileId,
      },
      tokens: { accessToken, refreshToken },
    };
  }

  public async refresh(refreshToken: string) {
    let decoded: any;
    try {
      decoded = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
    } catch {
      throw new UnauthorizedError('Invalid or expired refresh token');
    }

    const tokenHash = this.hashToken(decoded.token);
    const storedToken = await RefreshToken.findOne({ tokenHash, isRevoked: false });
    if (!storedToken || storedToken.expiresAt < new Date()) {
      throw new UnauthorizedError('Refresh token revoked or expired');
    }

    // Revoke old token (Token rotation - A6)
    storedToken.isRevoked = true;
    await storedToken.save();

    const user = await User.findById(decoded.id);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    let artisanProfileId: string | undefined;
    if (user.role === 'artisan') {
      const profile = await ArtisanProfile.findOne({ userId: user._id });
      if (profile) artisanProfileId = profile._id.toString();
    }

    const tokens = this.generateTokens(user, artisanProfileId);
    const newHash = this.hashToken(tokens.rawRefreshToken);
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    await RefreshToken.create({ userId: user._id, tokenHash: newHash, expiresAt });

    return {
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    };
  }

  public async logout(refreshToken: string) {
    try {
      const decoded: any = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET);
      const tokenHash = this.hashToken(decoded.token);
      await RefreshToken.updateOne({ tokenHash }, { isRevoked: true });
    } catch {
      // Gracefully ignore invalid tokens on logout
    }
  }

  public async getCurrentUser(userId: string) {
    const user = await User.findById(userId).select('-passwordHash');
    if (!user) throw new NotFoundError('User');
    let artisanProfile: any = null;
    if (user.role === 'artisan') {
      artisanProfile = await ArtisanProfile.findOne({ userId: user._id }).populate('category');
    }
    return { user: toPublicUser(user, artisanProfile?._id?.toString()), artisanProfile };
  }

  public async updateMe(userId: string, input: UpdateMeInput) {
    const user = await User.findById(userId);
    if (!user) throw new NotFoundError('User');
    if (input.fullName !== undefined) user.fullName = input.fullName;
    if (input.phone !== undefined) user.phone = input.phone;
    if (input.profilePicture !== undefined) user.profilePicture = input.profilePicture;
    await user.save();
    return this.getCurrentUser(userId);
  }

  public async changePassword(userId: string, input: ChangePasswordInput) {
    const user = await User.findById(userId);
    if (!user) throw new NotFoundError('User');
    const isMatch = await bcrypt.compare(input.currentPassword, user.passwordHash);
    if (!isMatch) throw new UnauthorizedError('Current password is incorrect');
    user.passwordHash = await bcrypt.hash(input.newPassword, await bcrypt.genSalt(10));
    await user.save();
    // Sign out every other session.
    await RefreshToken.updateMany({ userId: user._id, isRevoked: false }, { isRevoked: true });
  }
}

export const authService = new AuthService();
