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

# pragma once
# include <Siv3D/Common.hpp>
# include <Siv3D/Array.hpp>
# include <Siv3D/HashTable.hpp>
# include <Siv3D/Vertex2D.hpp>
# include <Siv3D/BlendState.hpp>
# include <Siv3D/RasterizerState.hpp>
# include <Siv3D/SamplerState.hpp>
# include <Siv3D/VertexShader.hpp>
# include <Siv3D/PixelShader.hpp>
# include <Siv3D/Renderer2D/CurrentBatchStateChanges.hpp>

namespace s3d
{
	enum class MetalRenderer2DCommandType : uint32
	{
		Null,

		SetBuffers,

		UpdateBuffers,

		Draw,

		DrawNull,
		
		BlendState,

		RasterizerState,

		PSSamplerState0,

		PSSamplerState1,

		PSSamplerState2,

		PSSamplerState3,

		PSSamplerState4,

		PSSamplerState5,

		PSSamplerState6,

		PSSamplerState7,

		SetVS,

		SetPS,
	};

	struct MetalRenderer2DCommand
	{
		MetalRenderer2DCommandType type = MetalRenderer2DCommandType::Null;

		uint32 index = 0;
		
		MetalRenderer2DCommand() = default;
		
		constexpr MetalRenderer2DCommand(MetalRenderer2DCommandType _type, uint32 _index) noexcept
			: type(_type)
			, index(_index) {}
	};

	struct MetalDrawCommand
	{
		uint32 indexCount = 0;
	};

	class MetalRenderer2DCommandManager
	{
	private:

		// commands
		Array<MetalRenderer2DCommand> m_commands;
		CurrentBatchStateChanges<MetalRenderer2DCommandType> m_changes;

		// buffer
		Array<MetalDrawCommand> m_draws;
		Array<uint32> m_nullDraws;
		Array<BlendState> m_blendStates				= { BlendState::Default };
		Array<RasterizerState> m_rasterizerStates	= { RasterizerState::Default2D };
		Array<VertexShader::IDType> m_VSs;
		Array<PixelShader::IDType> m_PSs;

		// current
		MetalDrawCommand m_currentDraw;
		BlendState m_currentBlendState				= m_blendStates.back();
		RasterizerState m_currentRasterizerState	= m_rasterizerStates.back();
		VertexShader::IDType m_currentVS			= VertexShader::IDType::InvalidValue();
		PixelShader::IDType m_currentPS				= PixelShader::IDType::InvalidValue();

		// reserved
		HashTable<VertexShader::IDType, VertexShader> m_reservedVSs;
		HashTable<PixelShader::IDType, PixelShader> m_reservedPSs;

	public:

		MetalRenderer2DCommandManager();

		void reset();

		void flush();

		const Array<MetalRenderer2DCommand>& getCommands() const noexcept;

		void pushUpdateBuffers(uint32 batchIndex);

		void pushDraw(Vertex2D::IndexType indexCount);
		const MetalDrawCommand& getDraw(uint32 index) const noexcept;


		void pushNullVertices(uint32 count);
		uint32 getNullDraw(uint32 index) const noexcept;
		
		void pushBlendState(const BlendState& state);
		const BlendState& getBlendState(uint32 index) const;
		const BlendState& getCurrentBlendState() const;

		void pushRasterizerState(const RasterizerState& state);
		const RasterizerState& getRasterizerState(uint32 index) const;
		const RasterizerState& getCurrentRasterizerState() const;

		void pushStandardVS(const VertexShader::IDType& id);
		void pushCustomVS(const VertexShader& vs);
		const VertexShader::IDType& getVS(uint32 index) const;

		void pushStandardPS(const PixelShader::IDType& id);
		void pushCustomPS(const PixelShader& ps);
		const PixelShader::IDType& getPS(uint32 index) const;
	};
}
