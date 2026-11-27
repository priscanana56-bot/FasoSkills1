import { Category } from './category.model.js';
import { ArtisanProfile } from '../artisans/artisan.model.js';
import { ServiceRequest } from '../requests/request.model.js';
import { NotFoundError, ConflictError } from '../../core/errors/app-error.js';
import type { CreateCategoryInput, UpdateCategoryInput } from './category.schema.js';

export class CategoryService {
  private slugify(text: string): string {
    return text
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toLowerCase()
      .trim()
      .replace(/[^\w\s-]+/g, '')
      .replace(/[\s_-]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }

  public async list(includeInactive = false) {
    const filter = includeInactive ? {} : { isActive: true };
    return Category.find(filter).sort({ name: 1 });
  }

  public async getById(id: string) {
    const category = await Category.findById(id);
    if (!category) throw new NotFoundError('Category');
    return category;
  }

  public async create(data: CreateCategoryInput) {
    const slug = this.slugify(data.name);
    const existing = await Category.findOne({
      $or: [{ slug }, { name: new RegExp(`^${data.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') }],
    });
    if (existing) throw new ConflictError('Category with this name already exists');

    return Category.create({ ...data, slug });
  }

  public async update(id: string, data: UpdateCategoryInput) {
    const category = await Category.findById(id);
    if (!category) throw new NotFoundError('Category');

    if (data.name !== undefined) {
      const slug = this.slugify(data.name);
      const conflict = await Category.findOne({
        _id: { $ne: id },
        $or: [
          { slug },
          { name: new RegExp(`^${data.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'i') },
        ],
      });
      if (conflict) throw new ConflictError('Category with this name already exists');
      category.name = data.name;
      category.slug = slug;
    }

    if (data.icon !== undefined) category.icon = data.icon;
    if (data.description !== undefined) category.description = data.description;
    if (data.isActive !== undefined) category.isActive = data.isActive;

    await category.save();
    return category;
  }

  public async remove(id: string): Promise<void> {
    const category = await Category.findById(id);
    if (!category) throw new NotFoundError('Category');

    const [usedByArtisan, usedByRequest] = await Promise.all([
      ArtisanProfile.exists({ category: id }),
      ServiceRequest.exists({ categoryId: id }),
    ]);

    if (usedByArtisan || usedByRequest) {
      throw new ConflictError(
        'Cannot delete category because it is currently used by artisans or service requests'
      );
    }

    await Category.deleteOne({ _id: id });
  }
}

export const categoryService = new CategoryService();
