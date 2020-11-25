//-----------------------------------------------
//
//	This file is part of the Siv3D Engine.
//
//	Copyright (c) 2008-2020 Ryo Suzuki
//	Copyright (c) 2016-2020 OpenSiv3D Project
//
//	Licensed under the MIT License.
//
//-----------------------------------------------

# include "CRenderer2D_Metal.hpp"
# include <Siv3D/Error.hpp>
# include <Siv3D/Resource.hpp>
# include <Siv3D/EngineLog.hpp>
# include <Siv3D/ScopeGuard.hpp>
# include <Siv3D/Mat3x2.hpp>
# include <Siv3D/ShaderCommon.hpp>
# include <Siv3D/Common/Siv3DEngine.hpp>
# include <Siv3D/Renderer/Metal/CRenderer_Metal.hpp>
# include <Siv3D/Shader/Metal/CShader_Metal.hpp>

///*
#	define LOG_COMMAND(...) LOG_TRACE(__VA_ARGS__)
/*/
#	define LOG_COMMAND(...) ((void)0)
//*/

namespace s3d
{
	CRenderer2D_Metal::CRenderer2D_Metal()
	{
	
	}

	CRenderer2D_Metal::~CRenderer2D_Metal()
	{
		LOG_SCOPED_TRACE(U"CRenderer2D_Metal::~CRenderer2D_Metal()");
	}

	void CRenderer2D_Metal::init()
	{
		LOG_SCOPED_TRACE(U"CRenderer2D_Metal::init()");
		
		pRenderer = dynamic_cast<CRenderer_Metal*>(SIV3D_ENGINE(Renderer));
		pShader = dynamic_cast<CShader_Metal*>(SIV3D_ENGINE(Shader));
		m_device = pRenderer->getDevice();
		m_commandQueue = pRenderer->getCommandQueue();
		m_swapchain = pRenderer->getSwapchain();

		// 標準 VS をロード
		{
			m_standardVS = std::make_unique<MetalStandardVS2D>();
			m_standardVS->sprite = MSL(U"VS_Sprite");
			m_standardVS->fullscreen_triangle = MSL(U"VS_FullscreenTriangle");
			if (!m_standardVS->setup())
			{
				throw EngineError(U"CRenderer2D_Metal::m_standardVS initialization failed");
			}
		}

		// 標準 PS をロード
		{
			m_standardPS = std::make_unique<MetalStandardPS2D>();
			m_standardPS->shape = MSL(U"PS_Shape");
			m_standardPS->fullscreen_triangle = MSL(U"PS_FullscreenTriangle");
			if (!m_standardPS->setup())
			{
				throw EngineError(U"CRenderer2D_Metal::m_standardPS initialization failed");
			}
		}
				
		//
		// RenderPipelineState の作成
		//
		{
			m_renderPipelineManager.init(pShader, m_device, *m_standardVS, *m_standardPS, m_swapchain.pixelFormat, pRenderer->getSampleCount());
		}
		
		m_renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
		
		// Batch 管理を初期化
		{
			if (not m_batches.init(m_device))
			{
				throw EngineError(U"MetalVertex2DBatch::init() failed");
			}
		}

		// バッファ作成関数を作成
		m_bufferCreator = [this](Vertex2D::IndexType vertexSize, Vertex2D::IndexType indexSize)
		{
			return m_batches.requestBuffer(vertexSize, indexSize, m_commandManager);
		};
	}

	void CRenderer2D_Metal::addLine(const Float2& begin, const Float2& end, const float thickness, const Float4(&colors)[2])
	{
		if (const auto indexCount = Vertex2DBuilder::BuildDefaultLine(m_bufferCreator, begin, end, thickness, colors))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}

			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addTriangle(const Float2(&points)[3], const Float4& color)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildTriangle(m_bufferCreator, points, color))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addTriangle(const Float2(&points)[3], const Float4(&colors)[3])
	{
		if (const auto indexCount = Vertex2DBuilder::BuildTriangle(m_bufferCreator, points, colors))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addRect(const FloatRect& rect, const Float4& color)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildRect(m_bufferCreator, rect, color))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addRect(const FloatRect& rect, const Float4(&colors)[4])
	{
		if (const auto indexCount = Vertex2DBuilder::BuildRect(m_bufferCreator, rect, colors))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addRectFrame(const FloatRect& rect, const float thickness, const Float4& innerColor, const Float4& outerColor)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildRectFrame(m_bufferCreator, rect, thickness, innerColor, outerColor))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addCircle(const Float2& center, const float r, const Float4& innerColor, const Float4& outerColor)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildCircle(m_bufferCreator, center, r, innerColor, outerColor, getMaxScaling()))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addCircleFrame(const Float2& center, const float rInner, const float thickness, const Float4& innerColor, const Float4& outerColor)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildCircleFrame(m_bufferCreator, center, rInner, thickness, innerColor, outerColor, getMaxScaling()))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addQuad(const FloatQuad& quad, const Float4& color)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildQuad(m_bufferCreator, quad, color))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addQuad(const FloatQuad& quad, const Float4(&colors)[4])
	{
		if (const auto indexCount = Vertex2DBuilder::BuildQuad(m_bufferCreator, quad, colors))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addLineString(const Vec2* points, const size_t size, const Optional<Float2>& offset, const float thickness, const bool inner, const Float4& color, const IsClosed isClosed)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildDefaultLineString(m_bufferCreator, points, size, offset, thickness, inner, color, isClosed, getMaxScaling()))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addLineString(const Vec2* points, const ColorF* colors, size_t size, const Optional<Float2>& offset, float thickness, bool inner, IsClosed isClosed)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildDefaultLineString(m_bufferCreator, points, colors, size, offset, thickness, inner, isClosed, getMaxScaling()))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addPolygon(const Array<Float2>& vertices, const Array<TriangleIndex>& indices, const Optional<Float2>& offset, const Float4& color)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildPolygon(m_bufferCreator, vertices, indices, offset, color))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addPolygon(const Vertex2D* vertices, const size_t vertexCount, const TriangleIndex* indices, const size_t num_triangles)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildPolygon(m_bufferCreator, vertices, vertexCount, indices, num_triangles))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addPolygonFrame(const Float2* points, const size_t size, const float thickness, const Float4& color)
	{
		if (const auto indexCount = Vertex2DBuilder::BuildPolygonFrame(m_bufferCreator, points, size, thickness, color, getMaxScaling()))
		{
			if (not m_currentCustomVS)
			{
				m_commandManager.pushStandardVS(m_standardVS->spriteID);
			}

			if (not m_currentCustomPS)
			{
				m_commandManager.pushStandardPS(m_standardPS->shapeID);
			}
			
			m_commandManager.pushDraw(indexCount);
		}
	}

	void CRenderer2D_Metal::addNullVertices(const uint32 count)
	{
		if (not m_currentCustomPS)
		{
			m_commandManager.pushStandardPS(m_standardPS->shapeID);
		}

		m_commandManager.pushNullVertices(count);
	}

	Optional<VertexShader> CRenderer2D_Metal::getCustomVS() const
	{
		return m_currentCustomVS;
	}

	Optional<PixelShader> CRenderer2D_Metal::getCustomPS() const
	{
		return m_currentCustomPS;
	}

	void CRenderer2D_Metal::setCustomVS(const Optional<VertexShader>& vs)
	{
		if (vs && (not vs->isEmpty()))
		{
			m_currentCustomVS = vs.value();
			m_commandManager.pushCustomVS(vs.value());
		}
		else
		{
			m_currentCustomVS.reset();
		}
	}

	void CRenderer2D_Metal::setCustomPS(const Optional<PixelShader>& ps)
	{
		if (ps && (not ps->isEmpty()))
		{
			m_currentCustomPS = ps.value();
			m_commandManager.pushCustomPS(ps.value());
		}
		else
		{
			m_currentCustomPS.reset();
		}
	}

	float CRenderer2D_Metal::getMaxScaling() const noexcept
	{
		return(1.0f);
	}

	void CRenderer2D_Metal::flush(id<MTLCommandBuffer> commandBuffer)
	{
		ScopeGuard cleanUp = [this]()
		{
			m_commandManager.reset();
			m_currentCustomVS.reset();
			m_currentCustomPS.reset();
		};
		
		m_commandManager.flush();
		
		m_batches.end();
		
		const Size currentRenderTargetSize = pRenderer->getSceneBufferSize();
		Mat3x2 transform = Mat3x2::Identity();
		Mat3x2 screenMat = Mat3x2::Screen(currentRenderTargetSize);
		const Mat3x2 matrix = transform * screenMat;
		
		const ColorF& backgroundColor = pRenderer->getBackgroundColor();
		
		m_vsConstants2D->transform[0] = Float4(matrix._11, -matrix._12, matrix._31, matrix._32);
		m_vsConstants2D->transform[1] = Float4(matrix._21, matrix._22, 0.0f, 1.0f);
		m_vsConstants2D->colorMul = Float4(1, 1, 1, 1);
		
		@autoreleasepool {

			if (1 == pRenderer->getSampleCount())
			{
				id<MTLTexture> sceneTexture = pRenderer->getSceneTexture();
				m_renderPassDescriptor.colorAttachments[0].texture = sceneTexture;
				m_renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(backgroundColor.r, backgroundColor.g, backgroundColor.b, 1);
				m_renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
				m_renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
			}
			else
			{
				id<MTLTexture> sceneTexture = pRenderer->getSceneTexture();
				id<MTLTexture> resolvedTexture = pRenderer->getResolvedTexture();
				m_renderPassDescriptor.colorAttachments[0].texture = sceneTexture;
				m_renderPassDescriptor.colorAttachments[0].resolveTexture = resolvedTexture;
				m_renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(backgroundColor.r, backgroundColor.g, backgroundColor.b, 1);
				m_renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
				m_renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionMultisampleResolve;
			}
		
			{
				id<MTLRenderCommandEncoder> sceneCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:m_renderPassDescriptor];
				{
					std::pair<VertexShader::IDType, PixelShader::IDType> currentSetShaders{ VertexShader::IDType::InvalidValue(), PixelShader::IDType::InvalidValue() };
					std::pair<VertexShader::IDType, PixelShader::IDType> currentShaders = currentSetShaders;
					BlendState currentSetBlendState = BlendState{ false, Blend{ 0 }};
					BlendState currentBlendState = currentSetBlendState;

					[sceneCommandEncoder setVertexBytes:m_vsConstants2D.data()
								   length:m_vsConstants2D.size()
								  atIndex:1];
					[sceneCommandEncoder setFragmentBytes:m_psConstants2D.data()
								   length:m_psConstants2D.size()
								  atIndex:1];
					
					BatchInfo2D batchInfo;
					size_t viBatchIndex = 0;
					
					LOG_COMMAND(U"----");
					
					for (const auto& command : m_commandManager.getCommands())
					{
						switch (command.type)
						{
						case MetalRenderer2DCommandType::Null:
							{
								LOG_COMMAND(U"Null");
								break;
							}
						case MetalRenderer2DCommandType::SetBuffers:
							{
								// do nothing

								LOG_COMMAND(U"SetBuffers[{}]"_fmt(command.index));
								break;
							}
						case MetalRenderer2DCommandType::UpdateBuffers:
							{
								viBatchIndex = command.index;
								batchInfo = m_batches.updateBuffers(viBatchIndex);
								
								[sceneCommandEncoder setVertexBuffer:m_batches.getCurrentVertexBuffer(viBatchIndex)
												offset:0
											   atIndex:0];

								LOG_COMMAND(U"UpdateBuffers[{}] BatchInfo(indexCount = {}, startIndexLocation = {}, baseVertexLocation = {})"_fmt(
									command.index, batchInfo.indexCount, batchInfo.startIndexLocation, batchInfo.baseVertexLocation));
								break;
							}
						case MetalRenderer2DCommandType::Draw:
							{
								if (currentSetShaders != currentShaders)
								{
									if ((currentShaders.first != VertexShader::IDType::InvalidValue())
										&& (currentShaders.second != PixelShader::IDType::InvalidValue()))
									{
										[sceneCommandEncoder setRenderPipelineState:
										 m_renderPipelineManager.get(currentShaders.first, currentShaders.second, MTLPixelFormatRGBA8Unorm, pRenderer->getSampleCount(), currentBlendState)];
									}
									
									currentSetBlendState = currentBlendState;
									currentSetShaders = currentShaders;
								}
								
								const MetalDrawCommand& draw = m_commandManager.getDraw(command.index);
								const uint32 indexCount = draw.indexCount;
								const uint32 startIndexLocation = batchInfo.startIndexLocation;

								[sceneCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
													indexCount:indexCount
													 indexType:MTLIndexTypeUInt16
												   indexBuffer:m_batches.getCurrentIndexBuffer(viBatchIndex)
											 indexBufferOffset:(sizeof(Vertex2D::IndexType) * startIndexLocation)];
								batchInfo.startIndexLocation += indexCount;

								LOG_COMMAND(U"Draw[{}] indexCount = {}, startIndexLocation = {}"_fmt(command.index, indexCount, startIndexLocation));
								break;
							}
						case MetalRenderer2DCommandType::DrawNull:
							{
								if (currentSetShaders != currentShaders)
								{
									if ((currentShaders.first != VertexShader::IDType::InvalidValue())
										&& (currentShaders.second != PixelShader::IDType::InvalidValue()))
									{
										[sceneCommandEncoder setRenderPipelineState:
										 m_renderPipelineManager.get(currentShaders.first, currentShaders.second, MTLPixelFormatRGBA8Unorm, pRenderer->getSampleCount(), currentBlendState)];
									}
									
									currentSetBlendState = currentBlendState;
									currentSetShaders = currentShaders;
								}

								const uint32 draw = m_commandManager.getNullDraw(command.index);

								// draw null vertex buffer
								{
									[sceneCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:draw];
								}

								LOG_COMMAND(U"DrawNull[{}] count = {}"_fmt(command.index, draw));
								break;
							}
						case MetalRenderer2DCommandType::BlendState:
							{
								const auto& blendState = m_commandManager.getBlendState(command.index);
								currentBlendState = blendState;
								LOG_COMMAND(U"BlendState[{}]"_fmt(command.index));
								break;
							}
						case MetalRenderer2DCommandType::RasterizerState:
							{
								const auto& rasterizerState = m_commandManager.getRasterizerState(command.index);
								pRenderer->getRasterizerState().set(sceneCommandEncoder, rasterizerState);
								LOG_COMMAND(U"RasterizerState[{}]"_fmt(command.index));
								break;
							}
						case MetalRenderer2DCommandType::SetVS:
							{
								const auto& vsID = m_commandManager.getVS(command.index);

								if (vsID == VertexShader::IDType::InvalidValue())
								{
									;// [Siv3D ToDo] set null
									LOG_COMMAND(U"SetVS[{}]: null"_fmt(command.index));
								}
								else
								{
									currentShaders.first = vsID;
									LOG_COMMAND(U"SetVS[{}]: {}"_fmt(command.index, vsID.value()));
								}

								break;
							}
						case MetalRenderer2DCommandType::SetPS:
							{
								const auto& psID = m_commandManager.getPS(command.index);

								if (psID == PixelShader::IDType::InvalidValue())
								{
									;// [Siv3D ToDo] set null
									LOG_COMMAND(U"SetPS[{}]: null"_fmt(command.index));
								}
								else
								{
									currentShaders.second = psID;
									LOG_COMMAND(U"SetPS[{}]: {}"_fmt(command.index, psID.value()));
								}

								break;
							}
						}
					}
				}
				[sceneCommandEncoder endEncoding];
			}
		}
	}

	void CRenderer2D_Metal::drawFullScreenTriangle(id<MTLCommandBuffer> commandBuffer, const TextureFilter textureFilter)
	{
		const ColorF& letterboxColor = pRenderer->getLetterboxColor();
		const auto [s, viewRect] = pRenderer->getLetterboxComposition();
		const MTLViewport viewport = { viewRect.x, viewRect.y, viewRect.w, viewRect.h, 0.0, 1.0 };
		const SamplerState samplerState = (textureFilter == TextureFilter::Linear) ? SamplerState::ClampLinear : SamplerState::ClampNearest;
		
		@autoreleasepool {
			
			id<MTLTexture> sceneTexture =  (1 == pRenderer->getSampleCount()) ? pRenderer->getSceneTexture() : pRenderer->getResolvedTexture();
			id<CAMetalDrawable> drawable = [m_swapchain nextDrawable];
			assert(drawable);

			m_renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(letterboxColor.r, letterboxColor.g, letterboxColor.b, 1);
			m_renderPassDescriptor.colorAttachments[0].loadAction  = MTLLoadActionClear;
			m_renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
			m_renderPassDescriptor.colorAttachments[0].texture = drawable.texture;
			m_renderPassDescriptor.colorAttachments[0].resolveTexture = nil;
			{
				id<MTLRenderCommandEncoder> fullscreenTriangleCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:m_renderPassDescriptor];
				{
					[fullscreenTriangleCommandEncoder setRenderPipelineState:m_renderPipelineManager.get(m_standardVS->fullscreen_triangle.id(), m_standardPS->fullscreen_triangle.id(), m_swapchain.pixelFormat, 1, BlendState::Opaque)];
					[fullscreenTriangleCommandEncoder setFragmentTexture:sceneTexture atIndex:0];
					[fullscreenTriangleCommandEncoder setViewport:viewport];
					pRenderer->getSamplerState().setPS(fullscreenTriangleCommandEncoder, 0, samplerState);
					[fullscreenTriangleCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
				}
				[fullscreenTriangleCommandEncoder endEncoding];
			}
			[commandBuffer presentDrawable:drawable];
			
			__weak dispatch_semaphore_t semaphore = m_batches.getSemaphore();
			[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer>)
			{
				dispatch_semaphore_signal(semaphore);
			}];
			
			[commandBuffer commit];
		}
	}

	void CRenderer2D_Metal::begin()
	{
		m_batches.begin();
	}
}
