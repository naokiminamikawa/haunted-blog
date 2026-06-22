# frozen_string_literal: true

class BlogsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  before_action :set_blog, only: %i[show edit update destroy]

  def index
    @blogs = Blog.search(params[:term]).published.default_order
  end

  def show
    return unless @blog.secret?
    return if user_signed_in? && @blog.owned_by?(current_user)

    head :not_found
  end

  def new
    @blog = Blog.new
  end

  def edit
    @blog = Blog.find(params[:id])
    head :not_found unless @blog.owned_by?(current_user)
  end

  def create
    @blog = current_user.blogs.new(blog_params)

    if @blog.save
      redirect_to blog_url(@blog), notice: 'Blog was successfully created.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @blog = Blog.find(params[:id])
    return head :not_found unless @blog.owned_by?(current_user)

    if @blog.update(blog_params)
      redirect_to blog_url(@blog), notice: 'Blog was successfully updated.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @blog = Blog.find(params[:id])
    return head :not_found unless @blog.owned_by?(current_user)

    @blog.destroy!

    redirect_to blogs_url, notice: 'Blog was successfully destroyed.', status: :see_other
  end

  private

  def set_blog
    @blog = Blog.find(params[:id])
  end

  def blog_params
    permitted_params = %i[title content secret]
    permitted_params << :random_eyecatch if current_user.premium?
    params.expect(blog: permitted_params)
  end
end
