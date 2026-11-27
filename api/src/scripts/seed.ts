import bcrypt from 'bcryptjs';
import { connectDatabase, disconnectDatabase } from '../config/database.js';
import { User } from '../modules/auth/auth.model.js';
import { Category } from '../modules/categories/category.model.js';
import { ArtisanProfile } from '../modules/artisans/artisan.model.js';
import { ServiceRequest } from '../modules/requests/request.model.js';
import { Quote } from '../modules/quotes/quote.model.js';
import { Review } from '../modules/reviews/review.model.js';
import { Conversation, Message } from '../modules/chat/chat.model.js';
import { ModerationLog, Report } from '../modules/reports/report.model.js';
import { Notification } from '../modules/notifications/notification.model.js';

async function seed() {
  await connectDatabase();
  console.log('🌱 Seeding database...');

  // Clear existing collections
  await Promise.all([
    User.deleteMany({}),
    Category.deleteMany({}),
    ArtisanProfile.deleteMany({}),
    ServiceRequest.deleteMany({}),
    Quote.deleteMany({}),
    Review.deleteMany({}),
    Conversation.deleteMany({}),
    Message.deleteMany({}),
    Report.deleteMany({}),
    ModerationLog.deleteMany({}),
    Notification.deleteMany({}),
  ]);

  const salt = await bcrypt.genSalt(10);
  const commonPassword = await bcrypt.hash('Password123!', salt);

  // 1. Categories
  const categories = await Category.create([
    { name: 'Plomberie', slug: 'plomberie', icon: 'plumbing', description: 'Installation, fuites, dépannage sanitaire' },
    { name: 'Électricité', slug: 'electricite', icon: 'electrical_services', description: 'Câblage, pannes, éclairage, tableaux' },
    { name: 'Menuiserie', slug: 'menuiserie', icon: 'carpenter', description: 'Meubles sur mesure, portes, fenêtres' },
    { name: 'Maçonnerie', slug: 'maconnerie', icon: 'foundation', description: 'Gros œuvre, rénovation, crépis, clôtures' },
    { name: 'Peinture', slug: 'peinture', icon: 'format_paint', description: 'Peinture intérieure, extérieure, décoration' },
    { name: 'Mécanique', slug: 'mecanique', icon: 'build', description: 'Réparation moto, voiture, entretien moteur' },
  ]);

  // 2. Users
  await User.create({
    email: 'admin@fasoskills.bf',
    phone: '+22670000001',
    fullName: 'Administrateur Principal',
    passwordHash: commonPassword,
    role: 'admin',
    isVerified: true,
  });

  const client1 = await User.create({
    email: 'client1@fasoskills.bf',
    phone: '+22670111111',
    fullName: 'Aminata Ouédraogo',
    passwordHash: commonPassword,
    role: 'client',
    isVerified: true,
  });

  const client2 = await User.create({
    email: 'client2@fasoskills.bf',
    phone: '+22670222222',
    fullName: 'Ibrahim Sawadogo',
    passwordHash: commonPassword,
    role: 'client',
    isVerified: true,
  });

  const artisanUser1 = await User.create({
    email: 'artisan1@fasoskills.bf',
    phone: '+22670333333',
    fullName: 'Moussa Kaboré',
    passwordHash: commonPassword,
    role: 'artisan',
    isVerified: true,
  });

  const artisanUser2 = await User.create({
    email: 'artisan2@fasoskills.bf',
    phone: '+22670444444',
    fullName: 'Seydou Traoré',
    passwordHash: commonPassword,
    role: 'artisan',
    isVerified: true,
  });

  const artisanUser3 = await User.create({
    email: 'artisan3@fasoskills.bf',
    phone: '+22670555555',
    fullName: 'Boubacar Compaoré',
    passwordHash: commonPassword,
    role: 'artisan',
    isVerified: false,
  });

  // 3. Artisan Profiles
  const profile1 = await ArtisanProfile.create({
    userId: artisanUser1._id,
    category: categories[0]._id, // Plomberie
    specialty: 'Plombier Sanitaire & Chauffe-eau',
    city: 'Ouagadougou',
    experienceYears: 7,
    bio: 'Artisan qualifié avec 7 ans d’expérience en dépannage et rénovation.',
    availability: 'Disponible 7j/7',
    rating: 4.8,
    reviewsCount: 12,
    completedJobs: 15,
    isVerified: true,
    verificationStatus: 'verified',
    documents: [
      { name: 'CNIB', type: 'id_card', url: 'https://cdn.fasoskills.bf/docs/moussa-cnib.jpg' },
      { name: 'Certificat de Qualification', type: 'certificate', url: 'https://cdn.fasoskills.bf/docs/moussa-cert.pdf' },
    ],
    profileStatus: 'complete',
  });

  const profile2 = await ArtisanProfile.create({
    userId: artisanUser2._id,
    category: categories[1]._id, // Electricite
    specialty: 'Électricien Bâtiment & Solaire',
    city: 'Bobo-Dioulasso',
    experienceYears: 5,
    bio: 'Installation solaire et dépannage électrique rapide.',
    availability: 'Disponible',
    rating: 4.6,
    reviewsCount: 8,
    completedJobs: 10,
    isVerified: true,
    verificationStatus: 'verified',
    documents: [
      { name: 'CNIB', type: 'id_card', url: 'https://cdn.fasoskills.bf/docs/seydou-cnib.jpg' },
    ],
    profileStatus: 'complete',
  });

  await ArtisanProfile.create({
    userId: artisanUser3._id,
    category: categories[2]._id, // Menuiserie
    specialty: 'Menuisier Bois & Aluminium',
    city: 'Koudougou',
    experienceYears: 4,
    bio: 'Fabrication de portes, fenêtres aluminium et mobilier sur mesure.',
    availability: 'Disponible',
    rating: 0,
    reviewsCount: 0,
    completedJobs: 0,
    isVerified: false,
    verificationStatus: 'pending',
    documents: [
      { name: 'CNIB Recto/Verso', type: 'id_card', url: 'https://cdn.fasoskills.bf/docs/boubacar-cnib.jpg' },
      { name: 'Attestation d’atelier', type: 'certificate', url: 'https://cdn.fasoskills.bf/docs/boubacar-atelier.pdf' },
    ],
    profileStatus: 'complete',
  });

  // 4. Service Requests
  const request1 = await ServiceRequest.create({
    clientId: client1._id,
    categoryId: categories[0]._id,
    title: 'Fuite d’eau importante sous évier de cuisine',
    description: 'Une fuite permanente sous l’évier inonde la cuisine. Besoin d’intervention rapide.',
    city: 'Ouagadougou',
    address: 'Karpala, Rue 14',
    status: 'pending',
  });

  const request2 = await ServiceRequest.create({
    clientId: client2._id,
    categoryId: categories[1]._id,
    title: 'Installation de panneau solaire et onduleur',
    description: 'Installation complète d’un kit solaire 3kVA avec batteries de secours.',
    city: 'Bobo-Dioulasso',
    address: 'Secteur 22',
    status: 'completed',
  });

  // 5. Quotes
  await Quote.create({
    requestId: request1._id,
    artisanId: profile1._id,
    amount: 15000,
    estimatedDays: 1,
    message: 'Je peux intervenir dès ce soir avec les pièces de rechange.',
    status: 'pending',
  });

  const quote2 = await Quote.create({
    requestId: request2._id,
    artisanId: profile2._id,
    amount: 125000,
    estimatedDays: 2,
    message: 'Devis incluant main-d’œuvre et câblage de sécurité.',
    status: 'accepted',
  });

  request2.acceptedQuoteId = quote2._id as any;
  await request2.save();

  // A mission in progress (client1 ↔ artisan1) and an open request without quotes.
  const request3 = await ServiceRequest.create({
    clientId: client1._id,
    categoryId: categories[0]._id,
    title: 'Remplacement chauffe-eau électrique 100L',
    description: 'Le chauffe-eau ne chauffe plus. Fourniture et pose d’un modèle 100L souhaitées.',
    city: 'Ouagadougou',
    address: 'Ouaga 2000, secteur 15',
    status: 'in_progress',
  });
  const quote3 = await Quote.create({
    requestId: request3._id,
    artisanId: profile1._id,
    amount: 85000,
    estimatedDays: 2,
    message: 'Chauffe-eau 100L garanti 2 ans, pose et évacuation de l’ancien inclus.',
    status: 'accepted',
  });
  request3.acceptedQuoteId = quote3._id as any;
  await request3.save();

  await ServiceRequest.create({
    clientId: client2._id,
    categoryId: categories[0]._id,
    title: 'Robinet de douche qui goutte',
    description: 'Le mitigeur de la douche fuit en continu, même fermé. Intervention cette semaine.',
    city: 'Ouagadougou',
    address: 'Tampouy',
    status: 'pending',
  });

  // 6. Review
  const review1 = await Review.create({
    requestId: request2._id,
    clientId: client2._id,
    artisanId: profile2._id,
    rating: 5,
    comment: 'Excellent travail, ponctuel et très professionnel !',
  });

  // 7. Chat conversation & sample message
  const conv = await Conversation.create({
    participants: [client1._id, artisanUser1._id],
    requestId: request3._id,
    lastMessage: 'Bonjour, je peux passer vers 16h.',
    lastSenderId: artisanUser1._id,
    lastMessageAt: new Date(),
  });

  const msg = await Message.create({
    conversationId: conv._id,
    senderId: artisanUser1._id,
    text: 'Bonjour, je peux passer vers 16h.',
    isRead: false,
  });

  // Starter notifications so both spaces show something on first launch.
  await Notification.create([
    {
      userId: client1._id,
      type: 'quote:received',
      title: 'Nouveau devis reçu',
      body: `${artisanUser1.fullName} propose 15 000 FCFA pour « ${request1.title} ».`,
      data: { requestId: request1._id.toString() },
    },
    {
      userId: artisanUser1._id,
      type: 'quote:accepted',
      title: 'Devis accepté 🎉',
      body: `Votre devis pour « ${request3.title} » a été accepté. La mission commence !`,
      data: { requestId: request3._id.toString() },
    },
  ]);

  // 8. Sample pending reports for Admin Moderation demo
  await Report.create([
    {
      reporterId: artisanUser1._id,
      targetType: 'request',
      targetId: request1._id,
      reason: 'Adresse imprécise',
      description: 'Le numéro de parcelle manque pour localiser le chantier.',
      status: 'pending',
      targetSnapshot: {
        title: request1.title,
        city: request1.city,
        authorName: client1.fullName,
      },
    },
    {
      reporterId: client2._id,
      targetType: 'review',
      targetId: review1._id,
      reason: 'Vérification de conformité',
      status: 'pending',
      targetSnapshot: {
        rating: review1.rating,
        comment: review1.comment,
        authorName: client2.fullName,
      },
    },
    {
      reporterId: client1._id,
      targetType: 'message',
      targetId: msg._id,
      reason: 'Vérification de message',
      status: 'pending',
      targetSnapshot: {
        text: msg.text,
        authorName: artisanUser1.fullName,
      },
    },
  ]);

  console.log('✅ Database seeded successfully!');
  console.log('Test Accounts (Password: Password123!):');
  console.log('- Admin: admin@fasoskills.bf');
  console.log('- Client: client1@fasoskills.bf');
  console.log('- Artisan (vérifié): artisan1@fasoskills.bf');
  console.log('- Artisan (en attente): artisan3@fasoskills.bf');

  await disconnectDatabase();
}

seed().catch((err) => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
