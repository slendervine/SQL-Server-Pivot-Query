



			IF OBJECT_ID('tempdb..##RELATORIO_VENDA_TEMP') IS NOT NULL DROP TABLE ##RELATORIO_VENDA_TEMP 
			IF OBJECT_ID('tempdb..##FINAL_TABLE') IS NOT NULL DROP TABLE ##FINAL_TABLE 
			
			DECLARE @SQLQUERY AS NVARCHAR(MAX) 
			DECLARE @PivotColumns AS NVARCHAR(MAX) 
			DECLARE @ColumnsSum AS NVARCHAR(MAX) 
			
			SELECT @ColumnsSum = COALESCE(@ColumnsSum + ',', '') + 'SUM(ISNULL(' + QUOTENAME(descMesVenda) + ', 0)) AS ' + QUOTENAME(descMesVenda) + ' ' 
			FROM 
			( 
				SELECT DATENAME(MONTH, V.dataVenda) AS descMesVenda 
					  ,MONTH( V.dataVenda) AS mesVenda 
				FROM usuarios U 
				INNER JOIN cliente C ON C.IdCliente = U.id 
				LEFT JOIN venda V ON V.IdCliente = C.id 
				WHERE U.id = 63 AND C.ativo = 1 
				AND V.cancel = 0 
				AND V.formaPagamento IN ('FA', 'CC') 
				AND V.dataVenda BETWEEN '2023-01-01' AND '2023-10-31'
			) AS tableTemp 
			GROUP BY descMesVenda 
					,mesVenda 
			ORDER BY mesVenda 
			
			SELECT @PivotColumns = COALESCE(@PivotColumns + ',', '') + QUOTENAME(descMesVenda) 
			FROM 
			( 
				SELECT DATENAME(MONTH, V.dataVenda) AS descMesVenda 
					  ,MONTH( V.dataVenda) AS mesVenda 
				FROM usuarios U 
				INNER JOIN cliente C ON C.IdCliente = U.id 
				LEFT JOIN venda V ON V.IdCliente = C.id
				WHERE U.id = 63 
				AND C.ativo = 1
				AND V.cancel = 0 
				AND V.formaPagamento IN ('FA', 'CC') 
				AND V.dataVenda BETWEEN '2023-01-01' AND '2023-10-31'
			) AS tableTemp
			GROUP BY descMesVenda 
					,mesVenda 
			ORDER BY mesVenda 
			
			SET @SQLQUERY = N'WITH tableTemp AS 
							( 
								SELECT   U.nome 
										,C.fantasia 
										,C.ni 
										,SUM(CAST(netbrl - overbrl AS DECIMAL(32,2))) AS valorTotal 
										,COUNT(V.id) AS qtdevenda 
										,DATENAME(MONTH, V.dataVenda) AS descMesVenda 
								FROM usuarios		  U
								INNER JOIN cliente C ON C.IdCliente = U.id 
								LEFT JOIN venda	  V ON V.IdCliente = C.id 
								WHERE U.id = 63 
								AND C.ativo = 1
								AND V.cancel = 0 
								AND V.formaPagamento IN (''FA'', ''CC'') 
								AND V.dataVenda BETWEEN ''2023-01-01'' AND ''2023-10-31'' 
								GROUP BY U.nome 
										,C.fantasia 
										,C.ni 
										,DATENAME(MONTH, V.dataVenda) 
							) 
							
							SELECT nome 
								  ,fantasia 
								  ,ni 
								  ,qtdevenda
								  , ' +@PivotColumns+' 
							INTO ##RELATORIO_VENDA_TEMP
							FROM tableTemp PIVOT (SUM([valorTotal]) FOR descMesVenda IN ('+@PivotColumns+')) AS Q' 
							
							exec sp_executesql @SQLQUERY 
							
							SET @SQLQUERY = ' SELECT ''NomeExemplo'' AS Fantasia 
													,''CodExemplo'' AS C 
													,'+@ColumnsSum+' 
											  INTO ##FINAL_TABLE 
											  FROM ##RELATORIO_VENDA_TEMP 
											  GROUP BY nome 
											  ,fantasia 
											  ,ni ' 
											  
							exec sp_executesql @SQLQUERY

							SELECT * FROM ##FINAL_TABLE