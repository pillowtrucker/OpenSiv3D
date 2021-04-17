﻿#include "..\MemoryReader.hpp"
//-----------------------------------------------
//
//	This file is part of the Siv3D Engine.
//
//	Copyright (c) 2008-2021 Ryo Suzuki
//	Copyright (c) 2016-2021 OpenSiv3D Project
//
//	Licensed under the MIT License.
//
//-----------------------------------------------

# pragma once

namespace s3d
{
	inline constexpr MemoryReader::MemoryReader(const void* data, const size_t size_bytes) noexcept
		: m_size{ static_cast<int64>(size_bytes) }
		, m_ptr{ static_cast<const Byte*>(data) } {}

	inline bool MemoryReader::supportsLookahead() const noexcept
	{
		return true;
	}

	inline bool MemoryReader::isOpen() const noexcept
	{
		return (m_ptr != nullptr);
	}

	inline int64 MemoryReader::size() const
	{
		return m_size;
	}

	inline int64 MemoryReader::getPos() const
	{
		return m_pos;
	}

	inline bool MemoryReader::setPos(const int64 pos)
	{
		if (not InRange<int64>(pos, 0, m_size))
		{
			return false;
		}

		m_pos = pos;

		return true;
	}

	inline int64 MemoryReader::skip(const int64 offset)
	{
		m_pos = Clamp<int64>((m_pos + offset), 0, m_size);

		return m_pos;
	}

	inline int64 MemoryReader::read(void* dst, const int64 size)
	{
		if (not dst)
		{
			return 0;
		}

		const int64 readSize = Clamp<int64>(size, 0, m_size - m_pos);

		std::memcpy(dst, (m_ptr + m_pos), static_cast<size_t>(readSize));

		m_pos += readSize;

		return readSize;
	}

	inline int64 MemoryReader::read(void* dst, const int64 pos, const int64 size)
	{
		if (not dst)
		{
			return 0;
		}

		const int64 readSize = Clamp<int64>(size, 0, m_size - pos);

		std::memcpy(dst, (m_ptr + pos), static_cast<size_t>(readSize));

		m_pos = pos + readSize;

		return readSize;
	}

	SIV3D_CONCEPT_TRIVIALLY_COPYABLE_
	inline bool MemoryReader::read(TriviallyCopyable& dst)
	{
		return read(std::addressof(dst), sizeof(TriviallyCopyable)) == sizeof(TriviallyCopyable);
	}

	inline int64 MemoryReader::lookahead(void* dst, const int64 size) const
	{
		if (not dst)
		{
			return 0;
		}

		const int64 readSize = Clamp<int64>(size, 0, m_size - m_pos);

		std::memcpy(dst, (m_ptr + m_pos), static_cast<size_t>(readSize));

		return readSize;
	}

	inline int64 MemoryReader::lookahead(void* dst, const int64 pos, const int64 size) const
	{
		if (not dst)
		{
			return 0;
		}

		const int64 readSize = Clamp<int64>(size, 0, m_size - pos);

		std::memcpy(dst, (m_ptr + m_pos), static_cast<size_t>(readSize));

		return readSize;
	}

	SIV3D_CONCEPT_TRIVIALLY_COPYABLE_
	inline bool MemoryReader::lookahead(TriviallyCopyable& dst) const
	{
		return lookahead(std::addressof(dst), sizeof(TriviallyCopyable)) == sizeof(TriviallyCopyable);
	}
}
